//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IGameFactory {
  struct TokenDetails {
    bool isForSale;
    bool isExist;
    address payable owner;
    uint256 id;
    uint256 amount;
    uint256 price;
  }
  
  function nftsForSale(address tokenAddress, uint256 tokenId) external view returns (TokenDetails memory);
}