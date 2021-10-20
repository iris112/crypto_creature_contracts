//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "../interfaces/IGameFactory.sol";
import "../interfaces/IBEP165.sol";
import "../interfaces/ITokenForSale.sol";
import "./Ownable.sol";

contract TokenForSale is Ownable, IBEP165 {

  uint256[] public idsForSale;
  // sale Id => index + 1 of idsForSale
  mapping (uint256 => uint256) public saleIndexForToken;
  // token Id => saleIds
  mapping (uint256 => uint256[]) public saleIdsForToken;
  
  address public gameFactory;

  modifier onlyGameFactory {
    require(
      gameFactory == msg.sender,
      "The caller of this function must be a GameFactory"
    );
    _;
  }

  constructor() {}

  function supportsInterface(bytes4 interfaceId) public view virtual override returns (bool) {
    return interfaceId == type(ITokenForSale).interfaceId;
  }

  function setGameFactory(address _gameFactory) external onlyOwner {
    gameFactory = _gameFactory;
  }

  function setForSale(uint256 tokenId, uint256 saleId) external onlyGameFactory {
    idsForSale.push(saleId);
    saleIdsForToken[tokenId].push(saleId);
    saleIndexForToken[saleId] = idsForSale.length;
  }

  function removeFromSale(uint256 tokenId, uint256 saleId) external onlyGameFactory {
    uint256 index = saleIndexForToken[saleId] - 1;
    uint256 length = idsForSale.length;

    require(index > 0, "TokenForSale: NOT_EXIST_TOKEN_SALE");
    idsForSale[index] = idsForSale[length - 1];
    idsForSale.pop();

    //ToDO: For ERC1155 with multiple sale
    saleIdsForToken[tokenId].pop();
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