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
    uint256 initialUnlockPercent;
    bool revocable;
    bool active;
  }

  struct VestingPool {
    uint256 strategy;
    uint256 cliff;
    uint256 start;
    uint256 duration;
    uint256 initialUnlockPercent;
    mapping(address => WhitelistInfo) whitelistPool;
    bool revocable;
    bool active;
  }

  struct MaxTokenTransferValue {
    uint256 amount;
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
   * inherit functions will be used in contract
   *
   */

  function getVestAmount(uint256 _option, address _wallet)
    external
    view
    returns (uint256);

  function getReleasableAmount(uint256 _option, address _wallet)
    external
    view
    returns (uint256);

  function getVestingInfo(uint256 _strategy)
    external
    view
    returns (VestingInfo memory);

  function setVestingInfo(
    uint256 _strategy,
    uint256 _cliff,
    uint256 _start,
    uint256 _duration,
    uint256 _initialUnlockPercent,
    bool _revocable
  ) external returns (bool);

  function addWhitelist(
    address _wallet,
    uint256 _dcbAmount,
    uint256 _option
  ) external returns (bool);

  function getWhitelist(uint256 _option, address _wallet)
    external
    view
    returns (WhitelistInfo memory);

  function setToken(address _addr) external returns (bool);

  function getToken() external view returns (address);

  function claimDistribution(uint256 _option, address _wallet)
    external
    returns (bool);
}
