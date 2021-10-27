// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.8;

interface IDecubateTiers {
  event OwnershipTransferred(
    address indexed previousOwner,
    address indexed newOwner
  );

  function tierInfo(uint256)
    external
    view
    returns (uint256 minLimit, uint256 maxLimit);

  function isEnabled() external view returns (bool);

  function owner() external view returns (address);

  function renounceOwnership() external;

  function transferOwnership(address newOwner) external;

  function addTier(uint256 _minLimit, uint256 _maxLimit)
    external
    returns (bool);

  function getTierOfUser(address addr)
    external
    view
    returns (
      bool flag,
      uint256 pos,
      uint256 multiplier
    );

  function setTier(
    uint256 tierId,
    uint256 _minLimit,
    uint256 _maxLimit
  ) external returns (bool);

  function getTotalDeposit(address addr) external view returns (uint256 amount);

  function getTiersLength() external view returns (uint256 len);
}
