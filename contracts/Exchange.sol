// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {errors} from "./libraries/Errors.sol";
import "./Vault.sol";


contract Exchange{
 
 address immutable _vaultAddress;
 using SafeERC20 for IERC20;

  constructor(address _vaultAdd){
    _vaultAddress = _vaultAdd;
  }
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

    mapping(address => Order) public placedOrders;
 

   

    function placeLimitOrder(address _tknselling,address _tknbuying, uint256 tknSellAmt, uint256 tknBuyAmt) external {
       Order storage order = placedOrders[msg.sender];
        order.maker= msg.sender;
        order.srcAmount= tknSellAmt;
        order.token0= _tknselling;
        order.token1= _tknbuying;
        order.exchangeRate = uint256(tknBuyAmt/ tknSellAmt);


        // sell - token0 
        // buy- token1


       
       Vault(_vaultAddress).placelimitOrder(_tknselling, tknSellAmt);

    }

   
    function withdrawLimitOrder() external {
       Order storage order = placedOrders[msg.sender];
       Vault(_vaultAddress).withdrawlimitOrder(order.token0, order.srcAmount);
    }


    function executeLimitOrder(address _tknselling,address _tknbuying, uint256 tknSellAmt, uint256 tknBuyAmt, address maker, address taker) external { 
    //    IERC20(_tknselling).safeTransferFrom(_vaultAddress, taker, tknSellAmt);
    //    IERC20(_tknbuying).safeTransferFrom(_vaultAddress, maker, tknBuyAmt);
       Vault(_vaultAddress).updatelimitOrderData(_tknbuying, tknBuyAmt, _tknselling, tknSellAmt);

    }
  

}