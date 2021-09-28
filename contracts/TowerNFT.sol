// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP721.sol";
import "./utils/BEP721Enumerable.sol";
import "./utils/TokenForSale.sol";
import "./library/Counter.sol";

contract TowerNFT is BEP721Enumerable, TokenForSale {
  using Counters for Counters.Counter;

  Counters.Counter internal tokenIdCounter;

  constructor() BEP721("TowerNFT", "TNFT")  {  
    _setBaseURI("https://cryptocreatures.org/api/TowerNFT/");
  }

  function supportsInterface(bytes4 interfaceId) public view override(BEP721Enumerable, TokenForSale) returns (bool) {
    return super.supportsInterface(interfaceId);
  }
  
  function mint() external onlyOwner returns(uint256) {
    return _mintItem(_msgSender());
  }

  function mintFor(address minter) external onlyGameFactory returns(uint256) {
    require(minter != address(0), "CreatureNFT: MINTER_IS_ZERO_ADDRESS");
    
    return _mintItem(minter);
  }

  function _mintItem(address minter) private returns(uint256) {
    tokenIdCounter.increment();
    uint256 newTokenId = tokenIdCounter.current();

    _safeMint(minter, newTokenId);

    return newTokenId;
  }
}

