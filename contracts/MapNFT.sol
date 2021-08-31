// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP721.sol";
import "./utils/Ownable.sol";
import "./library/Strings.sol";
import "./library/Address.sol";
import "./library/Counter.sol";

contract MapNFT is BEP721, Ownable {
  using Counters for Counters.Counter;
  using Strings for string;
  using Address for address;


  Counters.Counter internal tokenIdCounter;
  address public GameFactory;
  
  struct MapInfo {
    uint8 x;
    uint8 y;
    uint16 ground;
  }
  
  mapping(uint256 => MapInfo) public mapSize;
  mapping(uint256 => mapping(uint8 => mapping(uint8 => uint256))) public mapObjects;

  modifier onlyGameFactory {
    require(
      GameFactory == msg.sender,
      "The caller of this function must be a GameFactory"
    );
    _;
  }

  constructor() BEP721("MapNFT", "MNFT")  {  
    _setBaseURI("https://cryptocreatures.org/api/MapNFT/");
  }
  
  function mint(uint8 mapX, uint8 mapY, uint16 ground) external onlyOwner returns(uint256) {
    return _mintItem(_msgSender(), mapX, mapY, ground);
  }
  
  function save(uint256 mapId, uint256[] memory _itemIds, uint8[] memory _mapXs, uint8[] memory _mapYs) external onlyGameFactory returns (bool) {
    require(_itemIds.length == _mapXs.length, "MapNFT: INVALID_ARRAYS_LENGTH");
    require(_mapXs.length == _mapYs.length, "MapNFT: INVALID_ARRAYS_LENGTH");
    uint256 nIter = _itemIds.length;
    for (uint256 i = 0; i < nIter; i++) {
      mapObjects[mapId][_mapXs[i]][_mapYs[i]] = _itemIds[i];
    }
    return true;
  }
  
  function mintFor(address minter, uint8 mapX, uint8 mapY, uint16 ground) external onlyGameFactory returns (uint256) {
    require(minter != address(0), "CreatureNFT: MINTER_IS_ZERO_ADDRESS");

    return _mintItem(minter, mapX, mapY, ground);
  }
    
  function setGameFactory(address _GameFactory) external onlyOwner {
      GameFactory = _GameFactory;
  }

  function _mintItem(address minter, uint8 mapX, uint8 mapY, uint16 ground) private returns(uint256) {
    tokenIdCounter.increment();
    uint256 newTokenId = tokenIdCounter.current();

    _safeMint(minter, newTokenId);
    _approve(GameFactory, newTokenId);

    mapSize[newTokenId].x = mapX;
    mapSize[newTokenId].y = mapY;
    mapSize[newTokenId].ground = ground;

    return newTokenId;
  }
}

