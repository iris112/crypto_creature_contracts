// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP1155Tradable.sol";

contract MapNFTitems is BEP1155Tradable {
  
  constructor() BEP1155Tradable("MapNFTitems", "MNFTi", "https://cryptocreatures.org/api/MapNFTitems/")  {
    
  }

}

