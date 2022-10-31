// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import './Vault.sol';
import './Exchange.sol';

contract System {
    address public admin;
    Exchange public exchange;
    Vault public vault;

    constructor() {
        admin = msg.sender;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not authorized");
        _;
    }

    function setExchange(address _exchange) external onlyAdmin {
        exchange = Exchange(_exchange);
    }

    function setVault(address _vault) external onlyAdmin {
        vault = Vault(_vault);
    }
}