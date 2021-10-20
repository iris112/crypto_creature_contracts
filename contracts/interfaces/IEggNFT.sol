//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IEggNFT {
  struct EggInfo {
    uint256 firstId;
    uint256 secondId;
    uint256 blockNumber;
    address owner;
  }

  function mintFor(address account, uint256 firstId, uint256 secondId) external returns (uint256);
  function Eggs(uint256 eggId) external view returns (EggInfo memory);
}