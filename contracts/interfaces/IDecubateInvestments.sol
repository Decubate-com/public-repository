// SPDX-License-Identifier: MIT

//** Decubate IERC20 Library */
//** Author Vipin : Decubate Crowfunding 2021.5 */

pragma solidity ^0.8.8;

interface IDecubateInvestments {
  struct CrowdfundingEvent {
    string name;
    uint256 tokenPrice;
    string tokenSymbol;
    address vestingAddress;
    bool vestingActive;
    uint256 vestingId;
    bool isAirdrop;
    bool active;
  }

  struct UserInvestment {
    uint256 amount;
    bool active;
  }

  function addEvent(
    address _address,
    string memory name,
    uint256 tokenPrice,
    string memory tokenSymbol,
    address vestingAddress,
    bool vestingActive,
    uint256 vestingId,
    bool isAirdrop
  ) external returns (bool);

  function setEvent(
    address _address,
    string memory name,
    uint256 tokenPrice,
    string memory tokenSymbol,
    address vestingAddress,
    bool vestingActive,
    uint256 vestingId,
    bool isAirdrop
  ) external returns (bool);

  function getUserInvestments(address _address)
    external
    view
    returns (address[] memory addresses);

  function setUserInvestment(
    address _address,
    address _crowdfunding,
    uint256 _amount
  ) external returns (bool);

  function getInvestmentInfo(address _account, address _crowdfunding)
    external
    view
    returns (
      string memory name,
      uint256 invested,
      uint256 tokenPrice,
      string memory tokenSymbol,
      bool vestingActive,
      bool isAirdrop
    );

  function getVestingInfo(address _account, address _crowdfunding)
    external
    view
    returns (
      uint256 startDate,
      uint256 cliff,
      uint256 duration,
      uint256 total,
      uint256 released,
      uint256 available,
      uint256 initialUnlockPercent
    );

  function claimDistribution(address _account, address _crowdfunding)
    external
    returns (bool);
}
