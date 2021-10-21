//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IGameFactory.sol";
import "../interfaces/ITokenForBreeding.sol";
import "../interfaces/IEggNFT.sol";
import "./Ownable.sol";
import "./TokenForSale.sol";
import "../library/Counter.sol";

contract TokenForBreeding is TokenForSale {
  using Counters for Counters.Counter;

  uint256[] public idsForBreeding;
  // sale Id => index + 1 of idsForBreeding
  mapping (uint256 => uint256) public breedingIndexForToken;

  uint256 private _BREEDING_TIME = 200;    //block count = 200, time = 200 * 3s = 10min

  constructor() {}

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(ITokenForBreeding).interfaceId || super.supportsInterface(interfaceId);
  }

  function setBreedingTime(uint256 delay) external onlyOwner {
    _BREEDING_TIME = delay;
  }

  function setForBreeding(uint256 tokenId, uint256 saleId) external onlyGameFactory {
    idsForBreeding.push(saleId);
    saleIdsForToken[tokenId].push(saleId);
    breedingIndexForToken[saleId] = idsForBreeding.length;
  }

  function removeFromBreeding(uint256 tokenId, uint256 saleId) external onlyGameFactory {
    uint256 index = breedingIndexForToken[saleId] - 1;
    uint256 length = idsForBreeding.length;

    require(index > 0, "TokenForBreeding: NOT_EXIST_BREEDING");
    idsForBreeding[index] = idsForBreeding[length - 1];
    idsForBreeding.pop();

    saleIdsForToken[tokenId].pop();
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

  function mintFromEgg(uint256 eggId, address eggsToken) external returns (uint256) {
    require(eggId > 0, "TokenForBreeding: INVALID_EGGID");

    IEggNFT.EggInfo memory detail = IEggNFT(eggsToken).Eggs(eggId);
    require(detail.owner == _msgSender(), "TokenForBreeding: NOT_OWNER");

    if (block.number - detail.blockNumber > _BREEDING_TIME) {
      return _mintFromEgg();
    }

    return 0;
  }

  function _mintFromEgg() internal virtual returns (uint256) {}
}