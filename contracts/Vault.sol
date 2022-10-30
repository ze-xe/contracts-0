// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {errors} from "./libraries/Errors.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


contract Vault is Ownable {

   using SafeERC20 for IERC20;
   address immutable admin;
   address exchange;
    constructor(){
        admin = msg.sender;
    }
   mapping(address => mapping(address => uint256)) public userTokenBalance;
   mapping(address => mapping(address => uint256)) public userTokenBalanceInOrder;

   //check for insufficient balance
  function deposit( uint256 dAmt, address _tokenAdd) external {
    if (dAmt ==0) revert errors.ZeroAmt();
    IERC20(_tokenAdd).safeTransferFrom(msg.sender, address(this), dAmt);
    userTokenBalance[msg.sender][_tokenAdd] += dAmt;
    emit TokensDeposited(msg.sender, _tokenAdd, dAmt);
  }  


   function withdraw( uint256 wAmt, address _tokenAdd) external {
    if (userTokenBalance[msg.sender][_tokenAdd] < wAmt) revert errors.InsufficientVaultBalance(userTokenBalance[msg.sender][_tokenAdd]);
    IERC20(_tokenAdd).safeTransfer(msg.sender, wAmt);
    userTokenBalance[msg.sender][_tokenAdd] -= wAmt;
    emit TokenWithdrawn(msg.sender, _tokenAdd, wAmt);

  } 
  
   function getBalance(address _tokenAdd) view public returns(uint256) {
   return userTokenBalance[msg.sender][_tokenAdd];
   }

  // Update sellers asset details only on LIMITSELL
   function lockToken(address token, uint256 tknAmt, address account) external {
    if (msg.sender != exchange) revert errors.NotAuthorized();
     userTokenBalanceInOrder[account][token] += tknAmt;
     userTokenBalance[account][token] -= tknAmt;
   }

//   //Update data on order execution
//     function updatelimitOrderData(address _tknAssetAdded, uint256 tknAmtAdded, address _tknAssetSold, uint256 tknAmtSold) external {
//      userTokenBalance[msg.sender][_tknAssetAdded] += tknAmtAdded;
//      userTokenBalanceInOrder[msg.sender][_tknAssetSold] -= tknAmtSold;
//    }

  //Update data on order execution
    function increaseBalance(address token, address account, uint256 amt) external {
     if (msg.sender != exchange) revert errors.NotAuthorized();
     userTokenBalance[account][token] += amt;
    // userTokenBalanceInOrder[msg.sender][_tknAssetSold] -= tknAmtSold;
   }
   function decreaseBalance(address token, address account,  uint256 amt) external {
     if (msg.sender != exchange) revert errors.NotAuthorized();
     userTokenBalance[account][token] -= amt;
   }


  // Update sellers asset details only on LIMITSELL
   function unlockToken(address token, address account,  uint256 tknAmt) external {
     userTokenBalanceInOrder[account][token] -= tknAmt;
     userTokenBalance[account][token] += tknAmt;
   }

   function updateExchangeAddress(address _exchangeAdd) public onlyOwner{
      exchange = _exchangeAdd;
   }

  event TokensDeposited(address depositor, address tokenAdd, uint256 tokenAmt);
  event TokenWithdrawn(address depositor, address tokenAdd, uint256 tokenAmt);



}   