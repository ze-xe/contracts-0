// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {errors} from "./libraries/Errors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract Vault is Ownable {
    using SafeERC20 for IERC20;
    address public admin;
    address public exchange;

    constructor() {
        admin = msg.sender;
    }

    mapping(address => mapping(address => uint256)) public userTokenBalance;
    mapping(address => mapping(address => uint256)) public userTokenBalanceInOrder;

    // check for insufficient balance
    function deposit(address token, uint256 amount) external {
        if (amount == 0) revert errors.ZeroAmt();
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        userTokenBalance[msg.sender][token] += amount;
        emit TokensDeposited(msg.sender, token, amount);
    }

    function withdraw(address token, uint256 amount) external {
        if (userTokenBalance[msg.sender][token] < amount)
            revert errors.InsufficientVaultBalance(
                userTokenBalance[msg.sender][token]
            );
        IERC20(token).safeTransfer(msg.sender, amount);
        userTokenBalance[msg.sender][token] -= amount;
        emit TokenWithdrawn(msg.sender, token, amount);
    }

    function getBalance(address token) public view returns (uint256) {
        return userTokenBalance[msg.sender][token];
    }

    // Update sellers asset details only on LIMITSELL
    function lockToken(
        address token,
        uint256 amount,
        address account
    ) external onlyExchanger {
        userTokenBalanceInOrder[account][token] += amount;
    }

    //Update data on order execution
    function increaseBalance(
        address token,
        uint256 amount,
        address account
    ) external onlyExchanger {
        userTokenBalance[account][token] += amount;
    }

    function decreaseBalance(
        address token,
        uint256 amount,
        address account
    ) external onlyExchanger {
        userTokenBalance[account][token] -= amount;
    }

    // Update sellers asset details only on LIMITSELL
    function unlockToken(
        address token,
        uint256 amount,
        address account
    ) external onlyExchanger {
        userTokenBalanceInOrder[account][token] -= amount;
    }

    function updateExchangeAddress(address _exchangeAdd) public onlyOwner {
        exchange = _exchangeAdd;
    }

    modifier onlyExchanger() {
        require(msg.sender == exchange, "Only Exchanger can call this function");
        _;
    }

    event TokensDeposited(address account, address token, uint256 amount);
    event TokenWithdrawn(address account, address token, uint256 amount);
}
