// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { errors } from "./libraries/Errors.sol";
import "./Vault.sol";

contract Exchange {
    Vault public vault;
    using SafeERC20 for IERC20;

    enum OrderType {
        LIMITSELL,
        LIMITBUY
    }

    struct Order {
        address maker;
        address token0;
        address token1;
        uint256 orderType;
        uint256 exchangeRate;
        uint256 amount;
        uint256 fill;
    }

    struct Pair {
        address token0;
        address token1;
        uint256 exchangeRateDecimals;
        uint256 minToken0Order;
        uint256 minToken1Order;
    }

    mapping(bytes32 => Order) public placedOrders;
    mapping(bytes32 => Pair) public pairs;

    constructor(address _vault) {
        vault = Vault(_vault);
    }

    function createLimitOrder(
        address token0,
        address token1,
        uint256 amount,
        uint256 orderType,
        uint256 exchangeRate
    ) external {

        Pair memory pair = pairs[keccak256(abi.encodePacked(token0, token1))];
        if(pair.token0 == address(0)) revert errors.PairNotSupported();

        /* -------------------------------------------------------------------------- */
        /*                                 Validation                                 */
        /* -------------------------------------------------------------------------- */

        // exchange rate validation
        if(exchangeRate == 0) revert errors.InvalidExchangeRate(exchangeRate);

        // check for minimum order size
        if (orderType == uint256(OrderType.LIMITSELL)) {
            if (amount < pair.minToken0Order) revert errors.InvalidOrderAmount(amount);
        } else if (orderType == uint256(OrderType.LIMITBUY)) {
            if (amount < pair.minToken1Order) revert errors.InvalidOrderAmount(amount);
        } else {
            revert errors.InvalidOrderType(orderType);
        }

        // if (
        //     orderType == uint256(OrderType.LIMITSELL) &&
        //     uint256(token1Amt / token0Amt) != exchangeRate
        // ) revert errors.InvalidExchangeRate();

        bytes32 orderHash = keccak256(abi.encode(
            msg.sender,         // maker
            token0,             // token0
            token1,             // token1
            amount,             // amount
            orderType,          // orderType
            exchangeRate        // exchangeRate
        ));

        Order storage order = placedOrders[orderHash];
        order.maker = msg.sender;
        // order.srcAmount = token0Amt;
        order.token0 = token0;
        order.token1 = token1;
        order.exchangeRate = exchangeRate;

        if (orderType == uint256(OrderType.LIMITSELL)) {
            order.amount = amount;
            vault.lockToken(order.token0, amount, msg.sender);
        } else if (orderType == uint256(OrderType.LIMITBUY)) {
            order.amount = amount;
            vault.lockToken(order.token1, amount, msg.sender);
        }

        emit OrderCreated(
            orderHash,
            msg.sender,
            token0,
            token1,
            amount,
            exchangeRate,
            orderType
        );
    }

    function updateLimitOrder(bytes32 orderId, uint256 amount) external {
        Order storage order = placedOrders[orderId];

        if (order.orderType == uint256(OrderType.LIMITSELL)) {
            if (order.amount < amount) {
                vault.lockToken(order.token0, amount - order.amount, msg.sender);
            } else if (order.amount > amount) {
                vault.unlockToken(order.token0, order.amount - amount, msg.sender);
            }
        } else if (order.orderType == uint256(OrderType.LIMITBUY)) {
            if (order.amount < amount) {
                vault.lockToken(order.token1, amount - order.amount, msg.sender);
            } else if (order.amount > amount) {
                vault.unlockToken(order.token1, order.amount - amount, msg.sender);
            }
        }
        order.amount = amount;
    }

    function executeLimitOrder(bytes32 orderId, uint256 fillAmount) external {
        Order memory order = placedOrders[orderId];
        
        Pair memory pair = pairs[keccak256(abi.encodePacked(order.token0, order.token1))];
        if (order.orderType == uint256(OrderType.LIMITSELL)) {
            uint256 token1Amt = fillAmount * order.exchangeRate / 10**pair.exchangeRateDecimals;
            vault.increaseBalance(order.token1, order.maker, token1Amt);
            vault.unlockToken(order.token0, fillAmount, order.maker);
            vault.decreaseBalance(order.token0, order.maker, fillAmount);
        }
    }

    event OrderCreated(
        bytes32 orderId,
        address maker,
        address token0,
        address token1,
        uint256 amount,
        uint256 _exchangeRate,
        uint256 orderType
    );
}
