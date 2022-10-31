// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { Errors } from "./libraries/Errors.sol";
import "./Vault.sol";
import "./System.sol";

contract Exchange {
    using SafeERC20 for IERC20;

    event OrderCreated(
        bytes32 orderId,
        address maker,
        address token0,
        address token1,
        uint256 amount,
        uint256 _exchangeRate,
        uint256 orderType
    );

    event PairCreated(
        bytes32 pairId,
        address token0,
        address token1,
        uint256 exchangeRateDecimals,
        uint256 minToken0Order,
        uint256 minToken1Order
    );

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
    System public system;

    constructor(address _system) {
        system = System(_system);
    }

    function createPair(
        address token0,
        address token1,
        uint256 exchangeRateDecimals,
        uint256 minToken0Order,
        uint256 minToken1Order
    ) external {
        if(msg.sender != system.admin()) revert('NotAuthorized'); //Errors.NotAuthorized();

        bytes32 pairHash = keccak256(abi.encodePacked(token0, token1));
        Pair storage pair = pairs[pairHash];
        pair.token0 = token0;
        pair.token1 = token1;
        pair.exchangeRateDecimals = exchangeRateDecimals;
        pair.minToken0Order = minToken0Order;
        pair.minToken1Order = minToken1Order;

        emit PairCreated(
            pairHash,
            token0,
            token1,
            exchangeRateDecimals,
            minToken0Order,
            minToken1Order
        );
    }

    function createLimitOrder(
        address token0,
        address token1,
        uint256 amount,
        uint256 orderType,
        uint256 exchangeRate
    ) external {

        Pair memory pair = pairs[keccak256(abi.encodePacked(token0, token1))];
        if(pair.token0 == address(0)) revert('PairNotSupported'); // Errors.PairNotSupported();

        /* -------------------------------------------------------------------------- */
        /*                                 Validation                                 */
        /* -------------------------------------------------------------------------- */

        // exchange rate validation
        if(exchangeRate == 0) revert('InvalidExchangeRate'); // Errors.InvalidExchangeRate(exchangeRate);

        // check for minimum order size
        if (orderType == uint256(OrderType.LIMITSELL)) {
            if (amount < pair.minToken0Order) revert('InvalidOrderAmount'); // Errors.InvalidOrderAmount(amount);
        } else if (orderType == uint256(OrderType.LIMITBUY)) {
            if (amount < pair.minToken1Order) revert('InvalidOrderAmount'); // Errors.InvalidOrderAmount(amount);
        } else {
            revert('InvalidOrderType'); // Errors.InvalidOrderType(orderType);
        }

        // if (
        //     orderType == uint256(OrderType.LIMITSELL) &&
        //     uint256(token1Amt / token0Amt) != exchangeRate
        // ) revert(); // Errors.InvalidExchangeRate();

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
            system.vault().lockToken(order.token0, amount, msg.sender);
        } else if (orderType == uint256(OrderType.LIMITBUY)) {
            order.amount = amount;
            system.vault().lockToken(order.token1, amount, msg.sender);
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

        address token = order.orderType == uint256(OrderType.LIMITSELL)
            ? order.token0
            : order.token1;
        
        if (order.amount < amount) {
            uint extraAmount = amount - order.amount;
            system.vault().lockToken(token, extraAmount, msg.sender);
            system.vault().decreaseBalance(token, extraAmount, order.maker);
        } else if (order.amount > amount) {
            uint lessAmount = order.amount - amount;
            system.vault().unlockToken(token, lessAmount, msg.sender);
            system.vault().increaseBalance(token, lessAmount, order.maker);
        }

        order.amount = amount;
    }

    function executeLimitOrder(bytes32 orderId, uint256 fillAmount) external {
        // Order
        Order memory order = placedOrders[orderId];
        /* -------------------------------------------------------------------------- */
        /*                                 Validation                                 */
        /* -------------------------------------------------------------------------- */
        if(order.maker == address(0)) revert('OrderNotFound'); // Errors.OrderNotFound(orderId);
        if(order.amount - order.fill < fillAmount) revert('ZeroAmt'); // Errors.ZeroAmt();
        
        // Pair
        Pair memory pair = pairs[keccak256(abi.encodePacked(order.token0, order.token1))];

        uint256 token1Amount = fillAmount * order.exchangeRate / 10**pair.exchangeRateDecimals;

        if (order.orderType == uint256(OrderType.LIMITSELL)) {
            // decrement maker's token0 balance
            system.vault().unlockToken(order.token0, fillAmount, order.maker);
            system.vault().decreaseBalance(order.token0, fillAmount, order.maker);
            // decrement msg.sender's token1 balance
            system.vault().decreaseBalance(order.token1, token1Amount, msg.sender);
            // increment msg.sender's token0 balance
            system.vault().increaseBalance(order.token0, fillAmount, msg.sender);
            // increment maker's token1 balance
            system.vault().increaseBalance(order.token1, token1Amount, order.maker);
        } else if (order.orderType == uint256(OrderType.LIMITBUY)) {
            // decrement maker's token1 balance
            system.vault().unlockToken(order.token1, token1Amount, order.maker);
            system.vault().decreaseBalance(order.token1, token1Amount, order.maker);
            // decrement msg.sender's token0 balance
            system.vault().decreaseBalance(order.token0, fillAmount, msg.sender);
            // increment msg.sender's token1 balance
            system.vault().increaseBalance(order.token1, token1Amount, msg.sender);
            // increment maker's token0 balance
            system.vault().increaseBalance(order.token0, fillAmount, order.maker);
        }
    }
}
