// SPDX-License-Identifier: MIT

//** Decubate Crowdfunding Contract */
//** Author: Vipin & Aaron 2021.9 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./interfaces/IDecubateCrowdfunding.sol";
import "./interfaces/IWalletStore.sol";
import "./interfaces/IBracketAllocation.sol";
import "./interfaces/IDecubateTiers.sol";

contract DecubateCrowdfunding is
    IDecubateCrowdfunding,
    Ownable,
    ReentrancyGuard
{
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     *
     * @dev InvestorInfo is the struct type which store investor information
     *
     */
    struct InvestorInfo {
        uint256 joinDate;
        uint256 investAmount;
        address wallet;
        bool active;
    }

    /**
     *
     * @dev AgreementInfo will have information about agreement.
     * It will contains agreement details between innovator and investor.
     * For now, innovatorWallet will reflect owner of the platform.
     *
     */
    struct AgreementInfo {
        address innovatorWallet;
        uint256 softcap;
        uint256 hardcap;
        uint256 createDate;
        uint256 startDate;
        uint256 endDate;
        IERC20 token;
        uint256 vote;
        uint256 totalInvestFund;
        mapping(address => InvestorInfo) investorList;
    }

    /**
     *
     * @dev this variable is the instance of wallet storage
     *
     */
    IWalletStore private _walletStore;

    /**
     *
     * @dev this variable is the instance of Bracket contract
     *
     */
    IBracketAllocation private _bracketAlloc;

    /**
     *
     * @dev this variable is the instance of Tiers contract
     *
     */
    IDecubateTiers private _tiers;

    /**
     *
     * @dev this variable sets use of brackets
     *
     */
    bool public _useBrackets;

    /**
     *
     * @dev this variable stores total number of participants
     *
     */
    uint256 private _participantCount;

    /**
     *
     * @dev dcbAgreement store agreements info of this contract.
     *
     */
    AgreementInfo public dcbAgreement;

    constructor(
        address _walletStoreAddr,
        address _tiersAddr,
        address _innovator,
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _startDate,
        uint256 _endDate,
        address _token
    ) {
        _tiers = IDecubateTiers(_tiersAddr);
        _walletStore = IWalletStore(_walletStoreAddr);

        /** generate the new agreement */
        dcbAgreement.innovatorWallet = _innovator;
        dcbAgreement.softcap = _softcap;
        dcbAgreement.hardcap = _hardcap;
        dcbAgreement.createDate = block.timestamp;
        dcbAgreement.startDate = _startDate;
        dcbAgreement.endDate = _endDate;
        dcbAgreement.token = IERC20(_token);
        dcbAgreement.vote = 0;
        dcbAgreement.totalInvestFund = 0;

        /** emit the agreement generation event */
        emit CreateAgreement();
    }

    /**
     *
     * @dev set the terms of the agreement
     *
     * @param {_softcap} minimum amount to raise
     * @param {_hardcap} maximum amount to raise
     * @param {_startDate} date the fundraising starts
     * @param {_endDate} date the fundraising ends
     * @param {_token} token being used for fundraising
     * @return {bool} return status of operation
     *
     */
    function setDCBAgreement(
        uint256 _softcap,
        uint256 _hardcap,
        uint256 _startDate,
        uint256 _endDate,
        address _token
    ) external override onlyOwner returns (bool) {
        dcbAgreement.softcap = _softcap;
        dcbAgreement.hardcap = _hardcap;
        dcbAgreement.startDate = _startDate;
        dcbAgreement.endDate = _endDate;
        dcbAgreement.token = IERC20(_token);
        return true;
    }

    /**
     *
     * @dev set wallet store address for contract
     *
     * @param {_contract} address of wallet store
     * @return {bool} return status of operation
     *
     */
    function setWalletStoreAddress(address _contract)
        external
        override
        onlyOwner
        returns (bool)
    {
        _walletStore = IWalletStore(_contract);
        return true;
    }

    /**
     *
     * @dev set innovator wallet
     *
     * @param {_innovator} address of innovator
     * @return {bool} return status of operation
     *
     */
    function setInnovatorAddress(address _innovator)
        external
        override
        returns (bool)
    {
        require(
            msg.sender == dcbAgreement.innovatorWallet,
            "Only innovator can change"
        );
        dcbAgreement.innovatorWallet = _innovator;

        return true;
    }

    /**
     *
     * @dev set decubate tiers contract address
     *
     * @param {_contract} address of tiers contract
     * @return {bool} return status of operation
     *
     */
    function setTiersAddress(address _contract)
        external
        override
        onlyOwner
        returns (bool)
    {
        _tiers = IDecubateTiers(_contract);
        return true;
    }

    /**
     *
     * @dev set Bracket contract address for contract
     *
     * @param {_contract} address of Bracket contract
     * @param {_value} Enable/disable bracket usage
     * @return {bool} return status of token address
     *
     */
    function setUsingBrackets(address _contract, bool _value)
        external
        override
        onlyOwner
        returns (bool)
    {
        _bracketAlloc = IBracketAllocation(_contract);
        _useBrackets = _value;
        return true;
    }

    /**
     *
     * @dev getter function for total participants
     *
     * @return {uint256} return total participant count of crowdfunding
     *
     */
    function getInfo()
        public
        view
        override
        returns (
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256,
            uint256
        )
    {
        return (
            dcbAgreement.softcap,
            dcbAgreement.hardcap,
            dcbAgreement.createDate,
            dcbAgreement.startDate,
            dcbAgreement.endDate,
            dcbAgreement.totalInvestFund,
            _participantCount
        );
    }

    /**
     *
     * @dev Retrieve total amount of token from the contract
     *
     * @param {address} address of the token
     *
     * @return {uint256} total amount of token
     *
     */
    function getTotalToken() external view override returns (uint256) {
        return dcbAgreement.token.balanceOf(address(this));
    }

    /**
     *
     * @dev investor join available agreement
     *
     * @param {uint256} identifier of agreement
     * @param {uint256} actual join date for investment
     * @param {address} address of token which is going to use as deposit
     *
     * @return {bool} return if investor successfully joined to the agreement
     *
     */
    function fundAgreement(uint256 _investFund)
        external
        override
        nonReentrant
        returns (bool)
    {
        /** check if user is verified */
        require(_walletStore.isVerified(msg.sender), "User is not verified");

        /** check if investor is willing to invest any funds */
        require(_investFund > 0, "You cannot invest 0");

        /** check if startDate has started */
        require(
            block.timestamp >= dcbAgreement.startDate,
            "Crowdfunding not open"
        );

        /** check if endDate has already passed */
        require(block.timestamp < dcbAgreement.endDate, "Crowdfunding ended");

        require(
            dcbAgreement.totalInvestFund.add(_investFund) <=
                dcbAgreement.hardcap,
            "Hardcap already met"
        );

        /** Add to bracket if enabled */
        if (
            _useBrackets &&
            block.timestamp < dcbAgreement.startDate.add(4 hours)
        ) {
            // if user has no allocation yet, set allocation
            (bool active, uint256 allowedAmount) = _bracketAlloc.userAllocation(
                msg.sender
            );
            if (!active) {
                _bracketAlloc.setAddress(msg.sender);
                (, allowedAmount) = _bracketAlloc.userAllocation(msg.sender);
            }

            // make sure invest amount is not greater than allocated amount
            require(
                dcbAgreement.investorList[msg.sender].investAmount.add(
                    _investFund
                ) <= allowedAmount,
                "Amount is greater than allocation"
            );
        } else {
            // if not using brackets, require users are part of some tier to take part
            (bool flag, , ) = _tiers.getTierOfUser(msg.sender);
            require(flag, "User is not part of a tier");
        }

        if (!dcbAgreement.investorList[msg.sender].active) {
            /** add new investor to investor list for specific agreeement */
            dcbAgreement.investorList[msg.sender].wallet = msg.sender;
            dcbAgreement.investorList[msg.sender].investAmount = _investFund;
            dcbAgreement.investorList[msg.sender].joinDate = block.timestamp;
            dcbAgreement.investorList[msg.sender].active = true;
            _participantCount++;
        }
        // user has already deposited so update the deposit
        else {
            dcbAgreement.investorList[msg.sender].investAmount = dcbAgreement
                .investorList[msg.sender]
                .investAmount
                .add(_investFund);
        }

        dcbAgreement.totalInvestFund = dcbAgreement.totalInvestFund.add(
            _investFund
        );

        dcbAgreement.token.transferFrom(msg.sender, address(this), _investFund);

        emit NewInvestment(msg.sender, _investFund);

        return true;
    }

    /**
     *
     * @dev boilertemplate function for innovator to claim funds
     *
     * @param {address}
     *
     * @return {bool} return status of claim
     *
     */
    function claimInnovatorFund()
        external
        override
        nonReentrant
        returns (bool)
    {
        require(
            msg.sender == dcbAgreement.innovatorWallet,
            "Only innovator can claim"
        );

        /** check if endDate already passed and softcap is reached */
        require(
            (block.timestamp >= dcbAgreement.endDate &&
                dcbAgreement.totalInvestFund >= dcbAgreement.softcap) ||
                dcbAgreement.totalInvestFund >= dcbAgreement.hardcap,
            "Date and cap not met"
        );

        /** check if treasury have enough funds to withdraw to innovator */
        require(
            dcbAgreement.token.balanceOf(address(this)) >=
                dcbAgreement.totalInvestFund,
            "Not enough funds in treasury"
        );

        /** 
            transfer token from treasury to innovator
        */
        dcbAgreement.token.transfer(
            dcbAgreement.innovatorWallet,
            dcbAgreement.totalInvestFund
        );

        emit ClaimFund();
        return true;
    }

    /**
     *
     * @dev we will have function to transfer stable coins to company wallet
     *
     * @param {address} token address
     *
     * @return {bool} return status of the transfer
     *
     */

    function transferToken(uint256 _amount, address _to)
        external
        override
        onlyOwner
        returns (bool)
    {
        /** check if treasury have enough funds  */
        require(
            dcbAgreement.token.balanceOf(address(this)) >= _amount,
            "Not enough funds in treasury"
        );
        dcbAgreement.token.transfer(_to, _amount);

        emit TransferFund(_amount, _to);
        return true;
    }

    /**
     *
     * @dev Users can claim back their token if softcap isn't reached
     *
     * @return {bool} return status of the refund
     *
     */

    function refund() external override nonReentrant returns (bool) {
        /** check if user is an investor */
        require(
            dcbAgreement.investorList[msg.sender].wallet == msg.sender,
            "User is not an investor"
        );
        /** check if softcap has already reached */
        require(
            dcbAgreement.totalInvestFund < dcbAgreement.softcap,
            "Softcap already reached"
        );
        /** check if end date have passed or not */
        require(
            block.timestamp >= dcbAgreement.endDate,
            "End date not reached"
        );
        uint256 _amount = dcbAgreement.investorList[msg.sender].investAmount;

        /** check if contract have enough balance*/
        require(
            dcbAgreement.token.balanceOf(address(this)) >= _amount,
            "Not enough funds in treasury"
        );
        dcbAgreement.investorList[msg.sender].active = false;
        dcbAgreement.investorList[msg.sender].wallet = address(0);
        dcbAgreement.totalInvestFund = dcbAgreement.totalInvestFund.sub(
            dcbAgreement.investorList[msg.sender].investAmount
        );

        dcbAgreement.investorList[msg.sender].investAmount = 0;

        dcbAgreement.token.transfer(msg.sender, _amount);

        emit RefundProcessed(msg.sender, _amount);

        return true;
    }

    function userInvestment(address _address)
        external
        view
        override
        returns (uint256 investAmount, uint256 joinDate)
    {
        investAmount = dcbAgreement.investorList[_address].investAmount;
        joinDate = dcbAgreement.investorList[_address].joinDate;
    }
}
