//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ITokenForBreeding { 
  function setForBreeding(uint256 tokenId, uint256 saleId) external;
  function removeFromBreeding(uint256 tokenId, uint256 saleId) external;
}