//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IGameFactory.sol";
import "../interfaces/ITokenForBreeding.sol";
import "./Ownable.sol";
import "./TokenForSale.sol";

contract TokenForBreeding is TokenForSale {

  uint256[] public idsForBreeding;
  // sale Id => index + 1 of idsForBreeding
  mapping (uint256 => uint256) breedingIndexForToken;

  constructor() {}

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(ITokenForBreeding).interfaceId || super.supportsInterface(interfaceId);
  }

  function setForBreeding(uint256 saleId) external onlyGameFactory {
    idsForBreeding.push(saleId);
    breedingIndexForToken[saleId] = idsForBreeding.length;
  }

  function removeFromBreeding(uint256 saleId) external onlyGameFactory {
    uint256 index = breedingIndexForToken[saleId] - 1;
    uint256 length = idsForBreeding.length;

    require(index > 0, "TokenForSale: NOT_EXIST_TOKEN_SALE");
    idsForBreeding[index] = idsForBreeding[length - 1];
    idsForBreeding.pop();
  }

  function getAllOnBreeding(uint8 page, uint8 perPage) external view returns (IGameFactory.TokenDetails[] memory, uint256, uint256) {
    IGameFactory.TokenDetails[] memory ret = new IGameFactory.TokenDetails[](perPage);
    uint256 length = idsForBreeding.length;
    uint256 start = perPage * (page - 1);
    uint256 end = perPage * page;

    if (end > length)
      end = length;

    for (uint256 i = start; i < end; i++) {
      ret[i - start] = IGameFactory(gameFactory).nftsForSale(address(this), idsForBreeding[i]);
    }

    return (ret, end - start, length);
  }
}