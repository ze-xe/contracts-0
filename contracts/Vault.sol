// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {errors} from "./libraries/Errors.sol";


contract Vault {

   using SafeERC20 for IERC20;
   address immutable admin;
    constructor(){
        admin = msg.sender;
    }
   mapping(address => mapping(address => uint256)) public userTokenBalance;
   mapping(address => mapping(address => uint256)) public userTokenBalanceInOrder;

   //check for insufficient balance
  function Deposit( uint256 dAmt, address _tokenAdd) external {
    IERC20(_tokenAdd).safeTransferFrom(msg.sender, address(this), dAmt);
    userTokenBalance[msg.sender][_tokenAdd] += dAmt;
    emit tokensDeposited(msg.sender, _tokenAdd, dAmt);
  }  


   function Withdraw( uint256 wAmt, address _tokenAdd) external {
    if (userTokenBalance[msg.sender][_tokenAdd] < wAmt) revert errors.InsufficientVaultBalance(userTokenBalance[msg.sender][_tokenAdd]);
    IERC20(_tokenAdd).safeTransfer(msg.sender, wAmt);
    userTokenBalance[msg.sender][_tokenAdd] -= wAmt;
    emit tokenWithdrawn(msg.sender, _tokenAdd, wAmt);

  } 
  
   function getBalance(address _tokenAdd) view public returns(uint256) {
   return userTokenBalance[msg.sender][_tokenAdd];
   }

  // Update sellers asset details only on LIMITSELL
   function placelimitOrder(address _tknAssetforSale, uint256 tknAmt) external {
     userTokenBalanceInOrder[msg.sender][_tknAssetforSale] += tknAmt;
     userTokenBalance[msg.sender][_tknAssetforSale] -= tknAmt;
   }

  //Update data on order execution
    function updatelimitOrderData(address _tknAssetAdded, uint256 tknAmtAdded, address _tknAssetSold,uint256 tknAmtSold) external {
     userTokenBalance[msg.sender][_tknAssetAdded] += tknAmtAdded;
     userTokenBalanceInOrder[msg.sender][_tknAssetSold] -= tknAmtSold;
   }

  // Update sellers asset details only on LIMITSELL
   function withdrawlimitOrder(address _tknAssetforSale, uint256 tknAmt) external {
     userTokenBalanceInOrder[msg.sender][_tknAssetforSale] -= tknAmt;
     userTokenBalance[msg.sender][_tknAssetforSale] += tknAmt;
   }

  event tokensDeposited(address depositor, address tokenAdd, uint256 tokenAmt);
  event tokenWithdrawn(address depositor, address tokenAdd, uint256 tokenAmt);



}   