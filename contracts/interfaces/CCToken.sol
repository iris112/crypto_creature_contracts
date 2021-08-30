//SPDX-License-Identifier: MIT

pragma solidity 0.8.0;

interface CCToken {
  function moveFrom(address account, uint256 amount) external returns (bool);
  function moveTo(address account, uint256 amount) external returns (bool);
  function burnFrom(address account, uint256 amount) external returns (bool);
  function mintFor(address account, uint256 amount) external returns (bool);
}