//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IGameFactory.sol";
import "../interfaces/ITokenForBreeding.sol";
import "./Ownable.sol";
import "./TokenForSale.sol";
import "../library/Counter.sol";

contract TokenForBreeding is TokenForSale {
  using Counters for Counters.Counter;
  
  struct BreedingInfo {
    uint256 firstTokenId;
    uint256 secondTokenId;
    uint256 blockNumber;
    address owner;
  }

  uint256[] public idsForBreeding;
  uint256[] public idsForEgg;
  // sale Id => index + 1 of idsForBreeding
  mapping (uint256 => uint256) public breedingIndexForToken;
  // egg Id => index + 1 of idsForEgg
  mapping (uint256 => uint256) public eggIndexForToken;
  // egg Id => Breeding info
  mapping (uint256 => BreedingInfo) public breedingsForEgg;

  Counters.Counter internal eggIdCounter;
  uint256 private _BREEDING_TIME = 200;    //block count = 200, time = 200 * 3s = 10min

  event BreedingItem(uint256 firstId, uint256 secondId, address owner);

  constructor() {}

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(ITokenForBreeding).interfaceId || super.supportsInterface(interfaceId);
  }

  function setBreedingTime(uint256 delay) external onlyOwner {
    _BREEDING_TIME = delay;
  }

  function setForBreeding(uint256 saleId) external onlyGameFactory {
    idsForBreeding.push(saleId);
    breedingIndexForToken[saleId] = idsForBreeding.length;
  }

  function removeFromBreeding(uint256 saleId) external onlyGameFactory {
    uint256 index = breedingIndexForToken[saleId] - 1;
    uint256 length = idsForBreeding.length;

    require(index > 0, "TokenForBreeding: NOT_EXIST_BREEDING");
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

  function breeding(uint256 firstId, uint256 secondId, address owner) external onlyGameFactory {
    require(firstId > 0, "TokenForBreeding: INVALID_FIRST_TOKENID");
    require(secondId > 0, "TokenForBreeding: INVALID_SECOND_TOKENID");

    eggIdCounter.increment();
    uint256 newEggId = eggIdCounter.current();

    breedingsForEgg[newEggId] = BreedingInfo(firstId, secondId, block.number, owner);
    idsForEgg.push(newEggId);
    eggIndexForToken[newEggId] = idsForEgg.length;
    emit BreedingItem(firstId, secondId, owner);
  }

  function mintEgg(uint256 eggId) external returns (uint256) {
    BreedingInfo memory detail = breedingsForEgg[eggId];
    require(eggId > 0, "TokenForBreeding: INVALID_EGGID");
    require(detail.owner == _msgSender(), "TokenForBreeding: NOT_OWNER");

    if (block.number - detail.blockNumber > _BREEDING_TIME) {
      uint256 index = eggIndexForToken[eggId] - 1;
      uint256 length = idsForEgg.length;
      
      require(index > 0, "TokenForBreeding: NOT_EXIST_EGG");
      idsForEgg[index] = idsForEgg[length - 1];
      idsForEgg.pop();

      return _mintEgg();
    }

    return 0;
  }

  function _mintEgg() internal virtual returns (uint256) {}

  function getAllOnEgg(uint8 page, uint8 perPage) external view returns (BreedingInfo[] memory, uint256, uint256) {
    BreedingInfo[] memory ret = new BreedingInfo[](perPage);
    uint256 length = idsForEgg.length;
    uint256 start = perPage * (page - 1);
    uint256 end = perPage * page;

    if (end > length)
      end = length;

    for (uint256 i = start; i < end; i++) {
      ret[i - start] = breedingsForEgg[idsForEgg[i]];
    }

    return (ret, end - start, length);
  }
}