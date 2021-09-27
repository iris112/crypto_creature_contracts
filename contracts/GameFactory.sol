// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/Ownable.sol";
import "./library/SafeMath.sol";
import "./library/Strings.sol";
import "./library/Address.sol";
import "./interfaces/CCToken.sol";
import "./interfaces/CCNFT.sol";
import "./interfaces/IBEP20.sol";
import "./interfaces/IBEP721.sol";
import "./utils/BEP1155Tradable.sol";
import "./interfaces/IGameFactory.sol";
import "./interfaces/ITokenForSale.sol";
import "./library/Counter.sol";

contract GameFactory is Ownable {
  using Strings for string;
  using SafeMath for uint256;
  using Address for address;
  using Counters for Counters.Counter;
  
  address public gameToken;
  address public diamondToken;
  address public mapsToken;
  address public mapItemsToken;
  address public towersToken;
  address public towerItemsToken;
  address public creaturesToken;
  address public creatureItemsToken;
  uint256 public claimFee = 1e16;
  Counters.Counter internal saleIdCounter;

  //Mapping by marketplace listing by Id to token details.
  // token address => sale id => token details
  mapping(address => mapping(uint256 => IGameFactory.TokenDetails)) public nftsForSale;
  
  struct NFTAttribute {
    bool inWar;
    bool opened;
    bool staked;
    uint256 expiryDate;
    uint256 stakedJedi;
    uint256 stakedDarth;
    uint256 stakedPower;
  }

  event PriceItemAdded(address tokenAddress, uint256 saleId, uint256 tokenId, uint256 price, uint256 amount);
  event PriceItemRemoved(address tokenAddress, uint256 saleId, uint256 tokenId, uint256 price, uint256 amount);
  event PriceItemSold(address tokenAddress, uint256 saleId, uint256 tokenId, uint256 price, uint256 amount);
  event BreedingItemAdded(address tokenAddress, uint256 saleId, uint256 breedingTokenId, uint256 price, uint256 amount);
  event BreedingItemRemoved(address tokenAddress, uint256 saleId, uint256 breedingTokenId, uint256 price, uint256 amount);
  event BreedingItemSold(address tokenAddress, uint256 saleId, uint256 breedingTokenId, uint256 tokenId, uint256 price, uint256 amount);

  mapping (address => NFTAttribute) internal _settings;

  constructor() {}
  
  receive() external payable  {}
  
  function setGameToken(address _gameToken) external onlyOwner {
      gameToken = _gameToken;
  }
  
  function setDiamondToken(address _diamondToken) external onlyOwner {
      diamondToken = _diamondToken;
  }
  
  function setMapsToken(address _mapsToken) external onlyOwner {
      mapsToken = _mapsToken;
  }
  
  function setMapItemsToken(address _mapItemsToken) external onlyOwner {
      mapItemsToken = _mapItemsToken;
  }

  function setTowersToken(address _towersToken) external onlyOwner {
      towersToken = _towersToken;
  }
  
  function setTowerItemsToken(address _towerItemsToken) external onlyOwner {
      towerItemsToken = _towerItemsToken;
  }

  function setCreaturesToken(address _creaturesToken) external onlyOwner {
      creaturesToken = _creaturesToken;
  }
  
  function setCreatureItemsToken(address _creatureItemsToken) external onlyOwner {
      creatureItemsToken = _creatureItemsToken;
  }

  
  function mintMap(uint8 mapX, uint8 mapY, uint16 ground) external returns (uint256) {
    uint256 amount = uint256(mapX).mul(uint256(mapY)).mul(1e18);
    CCToken(gameToken).moveFrom(msg.sender, amount);
    uint256 mapId = CCNFT(mapsToken).mintFor(_msgSender(), mapX, mapY, ground);
    return mapId;
  }
  
  function saveMap(uint256 mapId, uint256[] memory _itemIds, uint8[] memory _mapXs, uint8[] memory _mapYs) external returns (bool) {
    require(_itemIds.length == _mapXs.length, "MapNFT: INVALID_ARRAYS_LENGTH");
    require(_mapXs.length == _mapYs.length, "MapNFT: INVALID_ARRAYS_LENGTH");
    require(CCNFT(mapsToken).ownerOf(mapId) == _msgSender(), "MapNFT:NOT_OWNER");
    bool result = CCNFT(mapsToken).save(mapId, _itemIds, _mapXs, _mapYs);
    return result;
  }

  function buyItem(address tokenAddress, uint256 saleId) external payable {
    IGameFactory.TokenDetails memory detail = nftsForSale[tokenAddress][saleId];

    _checkBuyPossible(detail);
    nftsForSale[tokenAddress][saleId].isForSale = false;
    detail.owner.transfer(msg.value);
    if (detail.amount > 1)
      BEP1155Tradable(tokenAddress).safeTransferFrom(detail.owner, _msgSender(), detail.tokenId, detail.amount, "");
    else
      IBEP721(tokenAddress).transferFrom(detail.owner, _msgSender(), detail.tokenId);
    ITokenForSale(tokenAddress).removeFromSale(saleId);
    
    emit PriceItemSold(tokenAddress, saleId, detail.tokenId, msg.value, detail.amount);
  }

  function _checkBuyPossible(IGameFactory.TokenDetails memory detail) private {
    require(_msgSender() != address(0), "BuyItem: INVALID_ADDRESS");
    require(detail.isForSale, "BuyItem: NOT_SELLING");
    require(detail.owner != _msgSender(), "BuyItem: IMPOSSIBLE_FOR_OWNER");
    require(msg.value >= detail.price * detail.amount, "BuyItem: LOWER_PRICE");
  }

  function sellItem(address tokenAddress, uint256 tokenId, uint256 price, uint256 amount) external {
    require(_msgSender() != address(0), "sellItemCancel: INVALID_ADDRESS");

    saleIdCounter.increment();
    uint256 newSaleId = saleIdCounter.current();
    nftsForSale[tokenAddress][newSaleId] = IGameFactory.TokenDetails(true, false, payable(_msgSender()), tokenId, amount, price);
    
    ITokenForSale(tokenAddress).setForSale(newSaleId);

    emit PriceItemAdded(tokenAddress, newSaleId, tokenId, price, amount);
  }

  function sellItemCancel(address tokenAddress, uint256 saleId) external {
    IGameFactory.TokenDetails memory detail = nftsForSale[tokenAddress][saleId];

    require(_msgSender() != address(0), "sellItemCancel: INVALID_ADDRESS");
    require(detail.isForSale, "sellItemCancel: NOT_SELLING");
    require(detail.owner == _msgSender(), "sellItemCancel: ONLY_FOR_OWNER");
    
    nftsForSale[tokenAddress][saleId].isForSale = false;
    ITokenForSale(tokenAddress).removeFromSale(saleId);
    
    emit PriceItemRemoved(tokenAddress, saleId, detail.tokenId, detail.price, detail.amount);
  }

  function setClaimFee(uint256 _claimFee) external onlyOwner {
    claimFee = _claimFee;
  }

  function withdrawToken(address _token, uint256 _amount) external onlyOwner {
    IBEP20(_token).transfer(msg.sender, _amount);
  }
  
  function withdraw(uint256 _amount) external onlyOwner {
    payable(msg.sender).transfer(_amount);
  }
}

