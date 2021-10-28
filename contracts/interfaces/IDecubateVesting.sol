// SPDX-License-Identifier: MIT

//** Decubate Vesting Factory Contract */
//** Author Vipin : Decubate Crowfunding 2021.5 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDecubateVesting {
  /**
   *
   * @dev this event will call when new token added to the contract
   * currently, we are supporting DCB token and this will be used for future implementation
   *
   */
  event AddToken(address token);

  /**
   *
   * @dev this event calls when new whitelist member joined to the pool
   *
   */
  event AddWhitelist(address wallet);

  /**
   *
   * @dev this event call when distirbuted token revoked
   *
   */
  event Revoked(address wallet);

  /**
   *
   * @dev this event call when roken claim is disabled for a user
   *
   */
  event Disabled(address wallet);

  /**
   *
   * @dev define vesting informations like x%, x months
   *
   */
  struct VestingInfo {
    uint256 strategy;
    uint256 cliff;
    uint256 start;
    uint256 duration;
    bool revocable;
    bool active;
  }

  struct VestingPool {
    uint256 strategy;
    uint256 cliff;
    uint256 start;
    uint256 duration;
    mapping(address => WhitelistInfo) whitelistPool;
    bool revocable;
    bool active;
  }

  /**
   *
   * @dev WhiteInfo is the struct type which store whitelist information
   *
   */
  struct WhitelistInfo {
    address wallet;
    uint256 dcbAmount;
    uint256 distributedAmount;
    uint256 joinDate;
    uint256 vestingOption;
    bool active;
    bool revoke;
    bool disabled;
  }

  /**
   *
   * @dev VIPInfo is the struct type which store unlock members after TGE
   *
   */
  struct VIPInfo {
    address wallet;
    uint256 unlockAmount;
    uint256 unlockTime;
    bool active;
  }

  /**
   *
   * inherit functions will be used in contract
   *
   */

  function setVestingInfo(
    uint256 _strategy,
    uint256 _cliff,
    uint256 _start,
    uint256 _duration,
    bool _revocable
  ) external returns (bool);

  function addWhitelist(
    address _wallet,
    uint256 _dcbAmount,
    uint256 _option
  ) external returns (bool);

  function setDecubateToken(IERC20 _token) external returns (bool);

  function getDecubateToken() external view returns (address);

  function claimDistribution(uint256 _option, address _wallet)
    external
    returns (bool);

  function addInitialUnlock(
    address _wallet,
    uint256 _amount,
    uint256 _time
  ) external returns (bool);

  function claimInitialUnlock() external returns (bool);
}
