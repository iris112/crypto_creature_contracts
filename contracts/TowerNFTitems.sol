// SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

import "./utils/BEP1155Tradable.sol";
import "./utils/TokenForSale.sol";

contract TowerNFTitems is TokenForSale, BEP1155Tradable {

  constructor() BEP1155Tradable("TowerNFTitems", "TNFTi", "https://cryptocreatures.org/api/TowerNFTitems/")  {
    
  }

}

