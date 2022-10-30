// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {errors} from "./libraries/Errors.sol";
import "./Vault.sol";

contract Exchange is EIP712 {
    address immutable _vaultAddress;
    using SafeERC20 for IERC20;

    constructor(address _vaultAdd) EIP712("LIMOLimitOrderDEX", "0.0.1") {
        _vaultAddress = _vaultAdd;
    }

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
        uint256 srcAmount;
    }

    //  mapping(address => Order) public placedOrders;  // user => order
    //bytes32==> order mapping

    uint256 decimalsAllowed = 4;
    mapping(bytes32 => Order) public placedOrders;

    function createLimitOrder(
        address token0,
        address token1,
        uint256 token0Amt,
        uint256 token1Amt,
        uint256 orderType,
        uint256 _exchangeRate
    ) external returns (bytes32) {
        //  uint256 _exchangeRate = uint256(token1Amt/ token0Amt);
        if (
            token0Amt == 0 ||
            token1Amt == 0 ||
            token0 == address(0) ||
            token1 == address(0) ||
            _exchangeRate == 0
        )
            revert errors.InvalidValues(
                token0Amt,
                token1Amt,
                token0,
                token1,
                _exchangeRate
            );
        if (
            orderType == uint256(OrderType.LIMITBUY) &&
            uint256(token0Amt / token1Amt) != _exchangeRate
        ) revert errors.InvalidExchangeRate();
        if (
            orderType == uint256(OrderType.LIMITSELL) &&
            uint256(token1Amt / token0Amt) != _exchangeRate
        ) revert errors.InvalidExchangeRate();

        bytes32 digest = keccak256(
            abi.encode(
                msg.sender,
                token0,
                token1,
                orderType,
                _exchangeRate,
                token0Amt
            )
        );

        Order storage order = placedOrders[digest];
        order.maker = msg.sender;
        // order.srcAmount= token0Amt;
        order.token0 = token0;
        order.token1 = token1;
        order.exchangeRate = _exchangeRate;

        if (orderType == uint256(OrderType.LIMITSELL)) {
            order.srcAmount = token0Amt;
            Vault(_vaultAddress).lockToken(order.token0, token0Amt, msg.sender);
            emit OrderCreatedLimitSell(
                digest,
                msg.sender,
                token0,
                token1,
                token0Amt,
                token1Amt,
                _exchangeRate
            );
        } else if (orderType == uint256(OrderType.LIMITBUY)) {
            order.srcAmount = token1Amt;
            Vault(_vaultAddress).lockToken(order.token1, token1Amt, msg.sender);
            emit OrderCreatedLimitBuy(
                digest,
                msg.sender,
                token0,
                token1,
                token0Amt,
                token1Amt,
                _exchangeRate
            );
        }

        return digest;
    }

    function withdrawLimitOrder(bytes32 _orderId) external {
        Order storage order = placedOrders[_orderId];

        if (order.orderType == uint256(OrderType.LIMITSELL)) {
            Vault(_vaultAddress).unlockToken(
                order.token0,
                order.maker,
                order.srcAmount
            );
        } else if (order.orderType == uint256(OrderType.LIMITBUY)) {
            Vault(_vaultAddress).unlockToken(
                order.token1,
                order.maker,
                order.srcAmount
            );
        }
    }

    function updateLimitOrder(
        bytes32 _orderId,
        uint256 token0Amt,
        uint256 token1Amt,
        uint256 _exchangeRate
    ) external {
        Order storage order = placedOrders[_orderId];
        if (order.orderType == uint256(OrderType.LIMITSELL)) {
            Vault(_vaultAddress).unlockToken(
                order.token0,
                order.maker,
                order.srcAmount
            );
            Vault(_vaultAddress).lockToken(order.token0, token0Amt, msg.sender);
        } else if (order.orderType == uint256(OrderType.LIMITBUY)) {
            Vault(_vaultAddress).unlockToken(
                order.token1,
                order.maker,
                order.srcAmount
            );
            Vault(_vaultAddress).lockToken(order.token1, token0Amt, msg.sender);
        }
    }

    function executeLimitOrder(bytes32 _orderId, uint256 fillAmount) external {
        if (placedOrders[_orderId].orderType == uint256(OrderType.LIMITSELL)) {
            uint256 token1Amt = fillAmount * placedOrders[_orderId].exchangeRate;
            Vault(_vaultAddress).increaseBalance(
                placedOrders[_orderId].token1,
                placedOrders[_orderId].maker,
                token1Amt
            );
            Vault(_vaultAddress).unlockToken(
                placedOrders[_orderId].token0,
                placedOrders[_orderId].maker,
                fillAmount
            );
            Vault(_vaultAddress).decreaseBalance(
                placedOrders[_orderId].token0,
                placedOrders[_orderId].maker,
                fillAmount
            );
        }
        //Limit Buy
    }

    event OrderCreatedLimitBuy(
        bytes32 orderId,
        address maker,
        address token0,
        address token1,
        uint256 token0Amt,
        uint256 token1Amt,
        uint256 _exchangeRate
    );
    event OrderCreatedLimitSell(
        bytes32 orderId,
        address maker,
        address token0,
        address token1,
        uint256 token0Amt,
        uint256 token1Amt,
        uint256 _exchangeRate
    );
}
