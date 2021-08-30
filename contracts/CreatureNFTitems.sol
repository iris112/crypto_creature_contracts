// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP1155Tradable.sol";

contract CreatureNFTitems is BEP1155Tradable {

  constructor() BEP1155Tradable("CreatureNFTitems", "CNFTi", "https://cryptocreatures.org/api/CreatureNFTitems/")  {
    
  }

}

