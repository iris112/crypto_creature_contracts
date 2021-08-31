//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP721.sol";
import "./utils/Ownable.sol";
import "./library/Counter.sol";

contract CreatureNFT is BEP721, Ownable {
  using Counters for Counters.Counter;

  Counters.Counter internal tokenIdCounter;
  address public GameFactory;
  
  modifier onlyGameFactory {
    require(
      GameFactory == msg.sender,
      "The caller of this function must be a GameFactory"
    );
    _;
  }

  constructor() BEP721("CreatureNFT", "CNFT")  {  
    _setBaseURI("https://cryptocreatures.org/api/CreatureNFT/");
  }
  
  function mint() external onlyOwner returns(uint256) {
    return _mintItem(_msgSender());
  }

  function mintFor(address minter) external onlyGameFactory returns(uint256) {
    require(minter != address(0), "CreatureNFT: MINTER_IS_ZERO_ADDRESS");
    
    return _mintItem(minter);
  }
    
  function setGameFactory(address _GameFactory) external onlyOwner {
    GameFactory = _GameFactory;
  }

  function _mintItem(address minter) private returns(uint256) {
    tokenIdCounter.increment();
    uint256 newTokenId = tokenIdCounter.current();

    _safeMint(minter, newTokenId);
    _approve(GameFactory, newTokenId);

    return newTokenId;
  }
}

