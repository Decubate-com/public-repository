// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.8;

interface IWalletStore {

  function isVerified(address) external view returns (bool);

  function addUser(address _address) external returns (bool);

  function replaceUser(address oldAddress, address newAddress) external returns (bool);

  function getVerifiedUsers() external view returns (address[] memory);
}
