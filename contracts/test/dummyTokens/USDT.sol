// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../TestERC20.sol";

contract USDT is TestERC20 {
    constructor() TestERC20("USD Tether", "USDT") {}
}