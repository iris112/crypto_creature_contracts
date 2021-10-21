//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface ITokenForSale { 
  function setForSale(uint256 tokenId, uint256 saleId) external;
  function removeFromSale(uint256 tokenId, uint256 saleId) external;
  function getCountOfSaleIdsForToken(uint256 tokenId) external view returns (uint256);
}