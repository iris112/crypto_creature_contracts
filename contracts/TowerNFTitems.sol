// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP1155Tradable.sol";

contract TowerNFTitems is BEP1155Tradable {

  constructor() BEP1155Tradable("TowerNFTitems", "TNFTi", "https://cryptocreatures.org/api/TowerNFTitems/")  {
    
  }

}

