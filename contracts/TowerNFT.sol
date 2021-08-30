// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP721.sol";
import "./utils/Ownable.sol";

contract TowerNFT is BEP721, Ownable {

  address public GameFactory;
  
  modifier onlyGameFactory {
      require(
          GameFactory == msg.sender,
          "The caller of this function must be a GameFactory"
      );
      _;
  }

  constructor() BEP721("TowerNFT", "TNFT")  {  
      _setBaseURI("https://cryptocreatures.org/api/TowerNFT/");
  }
  
  function mint(uint256 tokenId) external onlyOwner {
    _mint(msg.sender, tokenId);
  }

  
  function mintFor(address account, uint256 tokenId) external onlyGameFactory returns (bool) {
      _mint(account, tokenId);
      return true;
  }
    
  function setGameFactory(address _GameFactory) external onlyOwner {
      GameFactory = _GameFactory;
  }

}

