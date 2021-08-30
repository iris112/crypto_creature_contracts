//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface CCNFT {
  function mintFor(address account, uint8 mapX, uint8 mapY, uint16 ground) external returns (uint256);
  function save(uint256 mapId, uint256[] memory _itemIds, uint8[] memory _mapXs, uint8[] memory _mapYs) external returns (bool);
  function ownerOf(uint256 tokenId) external view returns (address);
}