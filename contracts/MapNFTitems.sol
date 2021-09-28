// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP1155Tradable.sol";
import "./utils/TokenForSale.sol";

contract MapNFTitems is BEP1155Tradable, TokenForSale {
  
  constructor() BEP1155Tradable("MapNFTitems", "MNFTi", "https://cryptocreatures.org/api/MapNFTitems/")  {
    
  }

  function supportsInterface(bytes4 interfaceId) public view override(BEP1155Tradable, TokenForSale) returns (bool) {
    return super.supportsInterface(interfaceId);
  }

}

