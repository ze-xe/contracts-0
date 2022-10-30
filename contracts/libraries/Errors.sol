// SPDX-License-Identifier: Apache 2.0
pragma solidity ^0.8.17;

library errors{
    error InsufficientVaultBalance(uint256 userBal);
    error ZeroAmt();
    error NotAuthorized();
    error InvalidValues(uint256 token0, uint256 token1, address  tokenAdd0, address  tokenAdd1, uint256 exchangeRate);
    error InvalidExchangeRate();
}