// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.6;

library Errors {
    error InsufficientVaultBalance(uint256);
    error ZeroAmt();
    error NotAuthorized();
    error InvalidValues(uint256 amount, address token0, address token1, uint orderType, uint256 exchangeRate);
    error InvalidExchangeRate(uint);
    error InvalidOrderType(uint);
    error InvalidOrderAmount(uint);
    error OrderNotFound(bytes32);
    error PairNotSupported();
}