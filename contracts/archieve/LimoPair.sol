// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract LimoPair {
    using SafeMath for uint256;
    
    address public token0;
    address public token1;

    uint256 public minToken0Order;
    uint256 public minToken1Order;
    uint256 public exchangeRateDecimals;

    address public limo;

    mapping(bytes32 => uint) public orderFills;

    constructor(address _token0, address _token1) {
        token0 = _token0;
        token1 = _token1;
        limo = msg.sender;
    }

    function exchange(address maker, address taker, bytes32 digest, uint256 exchangeRate, uint256 makerAmount, uint256 fillAmount) public {
        require(msg.sender == limo, "Only limo can call this function");
        // check amount
        require(fillAmount <= makerAmount, "Fill amount exceeds maker amount");

        // check fill amount
        orderFills[digest] += fillAmount;
        require(orderFills[digest] <= makerAmount, "Order fill amount exceeds order amount");

        // transfer tokens
        IERC20(token0).transferFrom(maker, taker, fillAmount);
        IERC20(token1).transferFrom(taker, maker, fillAmount.mul(10**exchangeRateDecimals).div(exchangeRate));
    }   
}