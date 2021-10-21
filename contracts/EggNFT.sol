//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP721Enumerable.sol";
import "./utils/TokenForSale.sol";
import "./utils/BEP721.sol";
import "./library/Counter.sol";
import "./interfaces/IEggNFT.sol";

contract EggNFT is BEP721Enumerable, TokenForSale {
  using Counters for Counters.Counter;

  event BreedingItem(uint256 firstId, uint256 secondId, address owner);

  // eggId -> Egg Info
  mapping(uint256 => IEggNFT.EggInfo) public Eggs;
  Counters.Counter internal tokenIdCounter;

  constructor() BEP721("EggNFT", "ENFT")  {  
    _setBaseURI("https://cryptocreatures.org/api/EggNFT/");
  }

  function supportsInterface(bytes4 interfaceId) public view override(BEP721Enumerable, TokenForSale) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
  
  function mint(uint256 firstId, uint256 secondId) external onlyOwner returns (uint256) {
    return _mintItem(_msgSender(), firstId, secondId);
  }

  function mintFor(address minter, uint256 firstId, uint256 secondId) external onlyGameFactory returns (uint256) {
    require(minter != address(0), "EggNFT: MINTER_IS_ZERO_ADDRESS");
    
    return _mintItem(minter, firstId, secondId);
  }

  function _mintItem(address minter, uint256 firstId, uint256 secondId) private returns(uint256) {
    tokenIdCounter.increment();
    uint256 newTokenId = tokenIdCounter.current();

    _safeMint(minter, newTokenId);

    Eggs[newTokenId].firstId = firstId;
    Eggs[newTokenId].secondId = secondId;
    Eggs[newTokenId].blockNumber = block.number;
    Eggs[newTokenId].owner = minter;

    emit BreedingItem(firstId, secondId, minter);

    return newTokenId;
  }
}