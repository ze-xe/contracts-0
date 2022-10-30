// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.17;

library errors{
    error InsufficientVaultBalance(uint256 userBal);
    error ZeroAmt();
    error NotAuthorized();
    error InvalidValues(uint256 amount, address token0, address token1, uint orderType, uint256 exchangeRate);
    error InvalidExchangeRate(uint);
    error InvalidOrderType(uint);
    error InvalidOrderAmount(uint);

    error PairNotSupported();
}