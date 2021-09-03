//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IGameFactory.sol";
import "./Ownable.sol";

contract BEP721ForSale is Ownable {

  uint256[] public idsForSale;
  // token Id => index + 1 of idsForSale
  mapping (uint256 => uint256) saleIndexForToken;
  
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

  function setForSale(uint256 tokenId) external {
    idsForSale.push(tokenId);
    saleIndexForToken[tokenId] = idsForSale.length;
  }

  function removeFromSale(uint256 tokenId) external {
    uint256 index = saleIndexForToken[tokenId] - 1;
    uint256 length = idsForSale.length;

    require(index > 0, "BEP721ForSale: NOT_EXIST_TOKEN_SALE");
    idsForSale[index] = idsForSale[length - 1];
    delete saleIndexForToken[tokenId];
    idsForSale.pop();
  }

  function getAllOnSale(uint8 page, uint8 perPage) external view returns (IGameFactory.TokenDetails[] memory, uint256, uint256) {
    IGameFactory.TokenDetails[] memory ret = new IGameFactory.TokenDetails[](perPage);
    uint256 length = idsForSale.length;
    uint256 start = perPage * (page - 1);
    uint256 end = perPage * page;

    if (end > length)
      end = length;

    for (uint256 i = start; i < end; i++) {
      ret[i - start] = IGameFactory(gameFactory).nftsForSale(address(this), idsForSale[i]);
    }

    return (ret, end - start, length);
  }  
}