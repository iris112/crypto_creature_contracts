//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface IBEP1155TokenReceiver {
  function onBEP1155Received(address _operator, address _from, uint256 _id, uint256 _amount, bytes calldata _data) external returns(bytes4);
  function onBEP1155BatchReceived(address _operator, address _from, uint256[] calldata _ids, uint256[] calldata _amounts, bytes calldata _data) external returns(bytes4);
  function supportsInterface(bytes4 interfaceID) external view returns (bool);
}