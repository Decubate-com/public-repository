// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

interface IBracketAllocation {
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function bracketInfo(uint256)
    external
    view
    returns (
      uint256 maxCount,
      uint256 currCount,
      uint256 allowedAmount
    );

  function getTierOfUser(address addr)
    external
    view
    returns (
      bool flag,
      uint256 pos,
      uint256 multiplier
    );

  function userAllocation(address)
    external
    view
    returns (bool active, uint256 allowedAmount);

  function isEnabled() external view returns (bool);

  function owner() external view returns (address);

  function renounceOwnership() external;

  function transferOwnership(address newOwner) external;

  function addBracket(
    uint256 _maxCount,
    uint256 _allowedAmount
  ) external returns (bool);

  function setBracket(
    uint256 _tierId,
    uint256 _maxCount,
    uint256 _allowedAmount
  ) external returns (bool);

  function getBracketUsers(uint8 tier)
    external
    view
    returns (address[] memory alist);

  function setAddress(address addr) external returns (bool);
}
