//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IGameFactory {
  struct TokenDetails {
    bool isForSale;
    bool isForBreeding;
    address payable owner;
    uint256 tokenId;
    uint256 amount;
    uint256 price;
  }
  
  function nftsForSale(address tokenAddress, uint256 saleId) external view returns (TokenDetails memory);
}