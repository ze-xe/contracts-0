// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import { Errors } from "./libraries/Errors.sol";
import "./Vault.sol";
import "./System.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "hardhat/console.sol";

contract Exchange {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;
    event OrderCreated(
        bytes32 orderId,
        bytes32 pair,
        address maker,
        uint256 amount,
        uint256 exchangeRate,
        uint256 orderType
    );

    event OrderExecuted(bytes32 orderId, address taker, uint fillAmount);

    event PairCreated(
        bytes32 pairId,
        address token0,
        address token1,
        uint256 exchangeRateDecimals,
        uint256 minToken0Order
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
        uint256 amount; // amount of token0
    }

    struct Pair {
        address token0;
        address token1;
        uint256 exchangeRateDecimals;
        uint256 minToken0Order;
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
        uint256 minToken0Order
    ) external {
        if(msg.sender != system.admin()) revert('NotAuthorized'); //Errors.NotAuthorized();

        bytes32 pairHash = keccak256(abi.encodePacked(token0, token1));
        Pair storage pair = pairs[pairHash];
        pair.token0 = token0;
        pair.token1 = token1;
        pair.exchangeRateDecimals = exchangeRateDecimals;
        pair.minToken0Order = minToken0Order;

        emit PairCreated(
            pairHash,
            token0,
            token1,
            exchangeRateDecimals,
            minToken0Order
        );
    }

    function createLimitOrder(
        address token0,
        address token1,
        uint256 amount, // amount of token0 to buy/sell
        uint256 orderType,
        uint256 exchangeRate,
        uint256 nonce
    ) external {
        bytes32 pairHash = keccak256(abi.encodePacked(token0, token1));
        Pair memory pair = pairs[pairHash];
        if(pair.token0 == address(0)) revert('PairNotSupported'); // Errors.PairNotSupported();

        /* -------------------------------------------------------------------------- */
        /*                                 Validation                                 */
        /* -------------------------------------------------------------------------- */

        // exchange rate validation
        if(exchangeRate == 0) revert('InvalidExchangeRate'); // Errors.InvalidExchangeRate(exchangeRate);

        // check for minimum order size        
        if (amount < pair.minToken0Order) revert('InvalidOrderAmount'); // Errors.InvalidOrderAmount(amount);
        
        bytes32 orderHash = keccak256(abi.encode(
            msg.sender,         // maker
            token0,             // token0
            token1,             // token1
            amount,             // amount
            orderType,          // orderType
            exchangeRate,       // exchangeRate
            nonce               // nonce
        ));
       console.log("Hs");
       console.logBytes32(orderHash);
        Order storage order = placedOrders[orderHash];
        order.maker = msg.sender;
        // order.srcAmount = token0Amt;
        order.token0 = token0;
        order.token1 = token1;
        order.exchangeRate = exchangeRate;
        order.amount = amount;

        // lock token0 or token1
        if (orderType == uint256(OrderType.LIMITSELL)) {
            system.vault().lockToken(order.token0, amount, msg.sender);
            system.vault().decreaseBalance(order.token0, amount, msg.sender);
        } else if (orderType == uint256(OrderType.LIMITBUY)) {
            uint token1Amount = amount.mul(exchangeRate).div(10**pair.exchangeRateDecimals);
            system.vault().lockToken(order.token1, token1Amount, msg.sender);
            system.vault().decreaseBalance(order.token1, token1Amount, msg.sender);
        }

        emit OrderCreated(
            orderHash,
            pairHash,
            msg.sender,
            amount,
            exchangeRate,
            orderType
        );
    }

    function updateLimitOrder(bytes32 orderId, uint256 amount) external {
        Order storage order = placedOrders[orderId];
        Pair memory pair = pairs[keccak256(abi.encodePacked(order.token0, order.token1))];

        address token = order.token0;
        
        if (order.amount < amount) {
            uint extraAmount = amount.sub(order.amount);
            if(order.orderType == uint256(OrderType.LIMITBUY)){
                token = order.token1;
                extraAmount = extraAmount.mul(order.exchangeRate).div(10**pair.exchangeRateDecimals);
            }
            system.vault().lockToken(token, extraAmount, msg.sender);
            system.vault().decreaseBalance(token, extraAmount, order.maker);
        } else if (order.amount > amount) {
            uint lessAmount = order.amount.sub(amount);
            if(order.orderType == uint256(OrderType.LIMITBUY)){
                token = order.token1;
                lessAmount = lessAmount.mul(order.exchangeRate).div(10**pair.exchangeRateDecimals);
            }
            system.vault().unlockToken(token, lessAmount, msg.sender);
            system.vault().increaseBalance(token, lessAmount, order.maker);
        }
        // update order amount
        order.amount = amount;
    }

    function executeLimitOrder(bytes32 orderId, uint256 fillAmount) external {
        // Order
        Order storage order = placedOrders[orderId];
        /* -------------------------------------------------------------------------- */
        /*                                 Validation                                 */
        /* -------------------------------------------------------------------------- */
        if(order.maker == address(0)) revert('OrderNotFound'); // Errors.OrderNotFound(orderId);

        // Pair
        Pair memory pair = pairs[keccak256(abi.encodePacked(order.token0, order.token1))];

        // minus fill amount from order
        order.amount -= fillAmount;
        

        uint256 token1FillAmount = fillAmount * order.exchangeRate / 10**pair.exchangeRateDecimals;
        if (order.orderType == uint256(OrderType.LIMITSELL)) {
            // unlock and decrement maker's token0 balance
            // increment msg.sender's token0 balance
            system.vault().unlockToken(order.token0, fillAmount, order.maker);
            system.vault().decreaseBalance(order.token0, fillAmount, order.maker);
            system.vault().increaseBalance(order.token0, fillAmount, msg.sender);
            // decrement msg.sender's token1 balance
            // increment maker's token1 balance
            system.vault().decreaseBalance(order.token1, token1FillAmount, msg.sender);
            system.vault().increaseBalance(order.token1, token1FillAmount, order.maker);

            // delete order if remaining order amount is less than minOrderAmount
            if (order.amount < pair.minToken0Order){
                system.vault().unlockToken(order.token0, order.amount, order.maker);
                delete placedOrders[orderId];
            }
        } else if (order.orderType == uint256(OrderType.LIMITBUY)) {
            // decrement msg.sender's token0 balance
            // increment maker's token0 balance
            system.vault().decreaseBalance(order.token0, fillAmount, msg.sender);
            system.vault().increaseBalance(order.token0, fillAmount, order.maker);
            // unlock and decrement maker's token1 balance
            // increment msg.sender's token1 balance
            system.vault().unlockToken(order.token1, token1FillAmount, order.maker);
            system.vault().decreaseBalance(order.token1, token1FillAmount, order.maker);
            system.vault().increaseBalance(order.token1, token1FillAmount, msg.sender);

            // delete order if remaining order amount is less than minOrderAmount
            if (order.amount < pair.minToken0Order){
                system.vault().unlockToken(order.token1, order.amount.mul(order.exchangeRate).div(10**pair.exchangeRateDecimals), order.maker);
                delete placedOrders[orderId];
            }
        }
        else {
            revert('InvalidOrderType'); // Errors.InvalidOrderType(order.orderType);
        }        
    }
}
