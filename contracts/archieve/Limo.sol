// SPDX-License-Identifier: MIT
pragma solidity ^0.8.6;

import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/utils/cryptography/SignatureChecker.sol";
import "@openzeppelin/contracts/utils/cryptography/draft-EIP712.sol";
import "@openzeppelin/contracts/interfaces/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./LimoPair.sol";

contract Limo is EIP712, Ownable {
    using SafeMath for uint256;

    event NewPair(address indexed token0, address indexed token1, address pair);

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

    mapping(bytes32 => address) public pairs;
    mapping(bytes32 => uint) public orderFills;

    constructor() EIP712("LIMOLimitOrderDEX", "0.0.1") {}

    function executeOrder(address maker, address token0, address token1, uint orderType, uint256 exchangeRate, uint256 srcAmount, uint256 fillAmount, bytes memory signature) external {
        // check signature
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
            keccak256("Order(address maker,address token0,address token1,uint256 orderType,uint256 exchangeRate,uint256 srcAmount)"),
            maker,
            token0,
            token1,
            orderType,
            exchangeRate,
            srcAmount
        )));
        // verify signature
        require(SignatureChecker.isValidSignatureNow(maker, digest, signature), "Invalid signature");

        // check fill amount
        orderFills[digest] += fillAmount;
        require(orderFills[digest] <= srcAmount, "Order fill amount exceeds order amount");

        
        // transfer tokens
        // sell => taker(msg.sender) sells token0 to maker for token1
        // buy => taker(msg.sender) buys token0 from maker for token1
        if (orderType == uint256(OrderType.LIMITSELL)) {
            IERC20(token0).transferFrom(msg.sender, maker, fillAmount);
            IERC20(token1).transferFrom(maker, msg.sender, fillAmount.mul(10**18).div(exchangeRate));
        } else if (orderType == uint256(OrderType.LIMITBUY)) {
            IERC20(token0).transferFrom(maker, msg.sender, fillAmount);
            IERC20(token1).transferFrom(msg.sender, maker, fillAmount.mul(10**18).div(exchangeRate));
        }
    }
}