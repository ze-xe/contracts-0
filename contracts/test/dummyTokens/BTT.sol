// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "../TestERC20.sol";

contract BTT is TestERC20 {
    constructor() TestERC20("Bit Torrent", "BTT") {}
}