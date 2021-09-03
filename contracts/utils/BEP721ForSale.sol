//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IGameFactory.sol";
import "./Ownable.sol";

contract BEP721ForSale is Ownable {

  uint256[] public idsForSale;
  address public gameFactory;

  modifier onlyGameFactory {
    require(
      gameFactory == msg.sender,
      "The caller of this function must be a GameFactory"
    );
    _;
  }

  constructor() {}

  function setGameFactory(address _gameFactory) external onlyOwner {
    gameFactory = _gameFactory;
  }

  function getAllOnSale(uint8 page, uint8 perPage) external view returns (IGameFactory.TokenDetails[] memory, uint256) {
    IGameFactory.TokenDetails[] memory ret = new IGameFactory.TokenDetails[](perPage);
    uint256[] memory data = idsForSale;
    uint256 start = perPage * (page - 1);
    uint256 end = perPage * page;

    if (end > data.length)
      end = data.length;

    for (uint256 i = start; i < end; i++) {
      ret[i - start] = IGameFactory(gameFactory).nftsForSale(address(this), data[i]);
    }

    return (ret, end - start);
  }  
}