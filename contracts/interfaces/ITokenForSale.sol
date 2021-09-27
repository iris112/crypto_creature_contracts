//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ITokenForSale { 
  function setForSale(uint256 saleId) external;
  function removeFromSale(uint256 saleId) external;
}