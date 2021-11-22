// SPDX-License-Identifier: MIT

//** Decubate Factory Contract */
//** Author Vipin */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IDecubateCrowdfunding {
  /**
   *
   * @dev this event will call when new agreement generated.
   * this is called when innovator create a new agreement but for now, it is calling when owner create new agreement
   *
   */
  event CreateAgreement();

  /**
   *
   * @dev it is calling when new investor joinning to the existing agreement
   *
   */
  event NewInvestment(address wallet, uint256 amount);

  /**
   *
   * @dev Called when an investor claims refund
   *
   */
  event RefundProcessed(address wallet, uint256 amount);

  /**
   *
   * @dev this event is called when innovator claim withdrawl
   *
   */
  event ClaimFund();

  /**
   *
   * @dev this event is called when transfer fund to other address
   *
   */
  event TransferFund(uint256 amount, address to);

  /**
   *
   * inherit functions will be used in contract
   *
   */
  function setWalletStoreAddress(address _contract) external returns (bool);

  function setInnovatorAddress(address _innovator) external returns (bool);

  function setInvestmentAddress(address _contract) external returns (bool);

  function setAllocation(address _address, uint256 _amount)
    external
    returns (bool);

  function setDCBAgreement(
    uint256 _softcap,
    uint256 _hardcap,
    uint256 _startDate,
    uint256 _endDate,
    address _token
  ) external returns (bool);

  function getInfo()
    external
    view
    returns (
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256,
      uint256
    );

  function getParticipants() external view returns (address[] memory);

  function getTotalToken() external view returns (uint256);

  function fundAgreement(uint256 _investFund) external returns (bool);

  function claimInnovatorFund() external returns (bool);

  function refund() external returns (bool);

  function transferToken(uint256 _amount, address _to) external returns (bool);

  function userInvestment(address _address)
    external
    view
    returns (uint256 investAmount, uint256 joinDate);
}
