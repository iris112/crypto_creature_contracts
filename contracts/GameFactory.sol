// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP721.sol";
import "./utils/Ownable.sol";
import "./library/SafeMath.sol";
import "./library/Strings.sol";
import "./library/Address.sol";
import "./interfaces/CCToken.sol";
import "./interfaces/CCNFT.sol";
import "./interfaces/IBEP20.sol";

contract GameFactory is BEP721, Ownable {
  using Strings for string;
  using SafeMath for uint256;
  using Address for address;
  
  address private _gameToken;
  address private _diamondToken;
  address private _mapsToken;
  address private _mapitemsToken;
  uint256 private _claimFee = 1e16;

  
  struct NFTAttribute {
    bool inWar;
    bool opened;
    bool staked;
    uint256 expiryDate;
    uint256 stakedJedi;
    uint256 stakedDarth;
    uint256 stakedPower;
  }

  mapping (address => NFTAttribute) internal _settings;

  constructor() BEP721("$DWARFNFT", "$DWARFNFT")  {  
      _setBaseURI("https://RPC-URI.com/api/BEP721/");
  }
  
  receive() external payable  {}
  
  function setGameToken(address gameToken_) external onlyOwner {
      _gameToken = gameToken_;
  }
  
  function setDiamondToken(address diamondToken_) external onlyOwner {
      _diamondToken = diamondToken_;
  }
  
  function setMapsToken(address mapsToken_) external onlyOwner {
      _mapsToken = mapsToken_;
  }
  
  function setMapitemsToken(address mapitemsToken_) external onlyOwner {
      _mapitemsToken = mapitemsToken_;
  }

  
  function mintMap(uint8 mapX, uint8 mapY, uint16 ground) external returns (uint256) {
    uint256 amount = uint256(mapX).mul(uint256(mapY)).mul(1e18);
    CCToken(_gameToken).moveFrom(msg.sender, amount);
    uint256 mapId = CCNFT(_mapsToken).mintFor(_msgSender(), mapX, mapY, ground);
    return mapId;
  }
  
  function save(uint256 mapId, uint256[] memory _itemIds, uint8[] memory _mapXs, uint8[] memory _mapYs) external returns (bool) {
    require(_itemIds.length == _mapXs.length, "MapNFT: INVALID_ARRAYS_LENGTH");
    require(_mapXs.length == _mapYs.length, "MapNFT: INVALID_ARRAYS_LENGTH");
    require(CCNFT(_mapsToken).ownerOf(mapId) == _msgSender(), "MapNFT:NOT_OWNER");
    bool result = CCNFT(_mapsToken).save(mapId, _itemIds, _mapXs, _mapYs);
    return result;
  }

  
  function setClaimFee(uint256 claimFee_) external onlyOwner {
      _claimFee = claimFee_;
  }

  function withdrawToken(address _token, uint256 _amount) external onlyOwner {
      IBEP20(_token).transfer(msg.sender, _amount);
  }
  
  function withdraw(uint256 _amount) external onlyOwner {
      payable(msg.sender).transfer(_amount);
  }


}

