//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ITokenForBreeding { 
  function setForBreeding(uint256 saleId) external;
  function removeFromBreeding(uint256 saleId) external;
  function breeding(uint256 firstId, uint256 secondId, address owner) external;
}