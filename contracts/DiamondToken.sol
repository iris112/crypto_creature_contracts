//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP20.sol";

// DiamondToken
contract DiamondToken is BEP20 {

  address public GameFactory;
  
  modifier onlyGameFactory {
      require(
          GameFactory == msg.sender,
          "The caller of this function must be a GameFactory"
      );
      _;
  }
  
  constructor() BEP20('Crypto creatures DiamondToken', 'CCDT') {
      _mint(msg.sender, 10000000000e18);
  }
  
  
  function moveFrom(address account, uint256 amount) external onlyGameFactory returns (bool) {
    _transfer(account, GameFactory, amount);
    return true;
  }
  
  function moveTo(address account, uint256 amount) external onlyGameFactory returns (bool) {
    _transfer(GameFactory, account, amount);
    return true;
  }
  
  function burnFrom(address account, uint256 amount) external onlyGameFactory returns (bool) {
      _burn(account, amount);
      return true;
  }
  
  function mintFor(address account, uint256 amount) external onlyGameFactory returns (bool) {
      _mint(account, amount);
      return true;
  }
    
  function setGameFactory(address _GameFactory) external onlyOwner {
      GameFactory = _GameFactory;
  }
    
}
