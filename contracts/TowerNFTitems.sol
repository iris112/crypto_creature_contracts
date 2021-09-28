// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP1155Tradable.sol";
import "./utils/TokenForSale.sol";

contract TowerNFTitems is BEP1155Tradable, TokenForSale {

  constructor() BEP1155Tradable("TowerNFTitems", "TNFTi", "https://cryptocreatures.org/api/TowerNFTitems/")  {
    
  }

  function supportsInterface(bytes4 interfaceId) public view override(BEP1155Tradable, TokenForSale) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

}

