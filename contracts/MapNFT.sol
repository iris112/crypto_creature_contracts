// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP721.sol";
import "./utils/Ownable.sol";
import "./library/Strings.sol";
import "./library/Address.sol";

contract MapNFT is BEP721, Ownable {
  using Strings for string;
  using Address for address;


  address private _GameFactory;
  uint256 private _lastId;
  
  struct MapInfo {
      uint8 x;
      uint8 y;
      uint16 ground;
  }
  
  mapping(uint256 => MapInfo) private _mapSize;
  mapping(uint256 => mapping(uint8 => mapping(uint8 => uint256))) private _mapObjects;

  modifier onlyGameFactory {
      require(
          _GameFactory == msg.sender,
          "The caller of this function must be a GameFactory"
      );
      _;
  }

  constructor() BEP721("MapNFT", "MNFT")  {  
      _setBaseURI("https://cryptocreatures.org/api/MapNFT/");
  }
  
  function mint(uint8 mapX, uint8 mapY, uint16 ground) external onlyOwner {
    _mint(msg.sender, _lastId);
    _mapSize[_lastId].x = mapX;
    _mapSize[_lastId].y = mapY;
    _mapSize[_lastId].ground = ground;
    _lastId++;
  }
  
  function save(uint256 mapId, uint256[] memory _itemIds, uint8[] memory _mapXs, uint8[] memory _mapYs) external onlyGameFactory returns (bool) {
    require(_itemIds.length == _mapXs.length, "MapNFT: INVALID_ARRAYS_LENGTH");
    require(_mapXs.length == _mapYs.length, "MapNFT: INVALID_ARRAYS_LENGTH");
    uint256 nIter = _itemIds.length;
    for (uint256 i = 0; i < nIter; i++) {
      _mapObjects[mapId][_mapXs[i]][_mapYs[i]] = _itemIds[i];
    }
    return true;
  }
  
  function mintFor(address account, uint8 mapX, uint8 mapY, uint16 ground) external onlyGameFactory returns (uint256) {
    uint256 id = _lastId;
    _mint(account, id);
    _mapSize[id].x = mapX;
    _mapSize[id].y = mapY;
    _mapSize[id].ground = ground;
    _lastId++;
    return id;
  }
    
  function setGameFactory(address GameFactory_) external onlyOwner {
      _GameFactory = GameFactory_;
  }

}

