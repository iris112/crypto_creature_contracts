//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IBEP721ForSale { 
  function setForSale(uint256 tokenId) external;
  function removeFromSale(uint256 tokenId) external;
}