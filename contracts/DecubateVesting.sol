// SPDX-License-Identifier: MIT

//** Decubate Locking Contract */
//** Author Vipin : Decubate Vesting Contract 2021.6 */

pragma solidity ^0.8.8;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/IDecubateVesting.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract DecubateVesting is IDecubateVesting, Ownable, ReentrancyGuard {
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    /**
     *
     * @dev whitelistPools store all active whitelist members.
     *
     */
    mapping(uint256 => VestingPool) public vestingPools;

    mapping(address => VIPInfo) public vipPools;

    IERC20 private _decubateToken;

    /**
     *
     * @dev setup VIP list for token distribution after TGE
     *
     */
    function addInitialUnlock(
        address _wallet,
        uint256 _amount,
        uint256 _time
    ) external override onlyOwner returns (bool) {
        require(!vipPools[_wallet].active, "VIP already exist");

        vipPools[_wallet].wallet = _wallet;
        vipPools[_wallet].unlockAmount = _amount;
        vipPools[_wallet].unlockTime = _time;
        vipPools[_wallet].active = true;

        return true;
    }

    /**
     *
     * @dev claim VIP distribution
     *
     */
    function claimInitialUnlock() external override returns (bool) {
        require(
            vipPools[msg.sender].active,
            "Wallet does not have an initial unlock to claim"
        );
        require(vipPools[msg.sender].unlockAmount > 0, "No unlock available");
        require(
            vipPools[msg.sender].unlockTime <= block.timestamp,
            "Claim not unlocked yet"
        );

        uint256 unlockAmount = vipPools[msg.sender].unlockAmount;
        vipPools[msg.sender].unlockAmount = 0;

        _decubateToken.transfer(vipPools[msg.sender].wallet, unlockAmount);

        return true;
    }

    /**
     *
     * @dev setup vesting plans for investors
     *
     * @param {uint256} indicate the distribution plan - seed, strategic and private
     * @param {uint256} duration in seconds of the cliff in which tokens will begin to vest
     * @param {uint256} vesting start date
     * @param {uint256} duration in seconds of the period in which the tokens will vest
     * @param {bool} whether the vesting is revocable or not
     *
     * @return {bool} status of the updating vesting plan
     *
     */
    function setVestingInfo(
        uint256 _strategy,
        uint256 _cliff,
        uint256 _start,
        uint256 _duration,
        bool _revocable
    ) external override onlyOwner returns (bool) {
        require(_strategy > 0, "Strategy should be correct");
        require(
            !vestingPools[_strategy].active,
            "Vesting option already exist"
        );

        vestingPools[_strategy].strategy = _strategy;
        vestingPools[_strategy].cliff = _start.add(_cliff);
        vestingPools[_strategy].start = _start;
        vestingPools[_strategy].duration = _duration;
        vestingPools[_strategy].revocable = _revocable;
        vestingPools[_strategy].active = true;

        return true;
    }

    /**
     *
     * @dev get vesting info
     *
     * @param {uint256} strategy of vesting info
     *
     * @return return vesting strategy
     *
     */
    function getVestingInfo(uint256 _strategy)
        external
        view
        returns (VestingInfo memory)
    {
        require(vestingPools[_strategy].active, "Vesting option is not exist");

        return
            VestingInfo({
                strategy: vestingPools[_strategy].strategy,
                cliff: vestingPools[_strategy].cliff,
                start: vestingPools[_strategy].start,
                duration: vestingPools[_strategy].duration,
                revocable: vestingPools[_strategy].revocable,
                active: vestingPools[_strategy].active
            });
    }

    /**
     *
     * @dev set the address as whitelist user address
     *
     * @param {address} address of the user
     *
     * @return {bool} return status of the whitelist
     *
     */
    function addWhitelist(
        address _wallet,
        uint256 _dcbAmount,
        uint256 _option
    ) external override onlyOwner returns (bool) {
        require(vestingPools[_option].active, "Vesting option is not existing");
        require(
            vestingPools[_option].whitelistPool[_wallet].wallet != _wallet,
            "Whitelist already available"
        );
        vestingPools[_option].whitelistPool[_wallet].wallet = _wallet;
        vestingPools[_option].whitelistPool[_wallet].dcbAmount = _dcbAmount;
        vestingPools[_option].whitelistPool[_wallet].distributedAmount = 0;
        vestingPools[_option].whitelistPool[_wallet].joinDate = block.timestamp;
        vestingPools[_option].whitelistPool[_wallet].vestingOption = _option;
        vestingPools[_option].whitelistPool[_wallet].active = true;

        emit AddWhitelist(_wallet);

        return true;
    }

    /**
     *
     * @dev set the address as whitelist user address
     *
     * @param {address} address of the user
     *
     * @return {Whitelist} return whitelist instance
     *
     */
    function getWhitelist(uint256 _option, address _wallet)
        external
        view
        returns (WhitelistInfo memory)
    {
        require(vestingPools[_option].active, "Vesting option is not existing");
        require(
            vestingPools[_option].whitelistPool[_wallet].wallet == _wallet,
            "Whitelist is not existing"
        );

        return vestingPools[_option].whitelistPool[_wallet];
    }

    /**
     *
     * @dev set decubate token address for contract
     *
     * @param {_token} address of IERC20 instance
     * @return {bool} return status of token address
     *
     */
    function setDecubateToken(IERC20 _token)
        external
        override
        onlyOwner
        returns (bool)
    {
        _decubateToken = _token;
        return true;
    }

    /**
     *
     * @dev getter function for deployed decubate token address
     *
     * @return {address} return deployment address of decubate token
     *
     */
    function getDecubateToken() external view override returns (address) {
        return address(_decubateToken);
    }

    /**
     *
     * @dev distribute the token to the investors
     *
     * @param {address} wallet address of the investor
     *
     * @return {bool} return status of distribution
     *
     */
    function claimDistribution(uint256 _option, address _wallet)
        external
        override
        nonReentrant
        returns (bool)
    {
        require(
            !vestingPools[_option].whitelistPool[_wallet].disabled,
            "User is disabled from claiming token"
        );
        uint256 releaseAmount = calculateReleasableAmount(_option, _wallet);
        require(releaseAmount > 0, "Zero amount to claim");
        _decubateToken.transfer(_wallet, releaseAmount);
        vestingPools[_option]
            .whitelistPool[_wallet]
            .distributedAmount += releaseAmount;

        return true;
    }

    /**
     *
     * @dev calculate releasable amount by subtracting distributed amount
     *
     * @param {address} investor wallet address
     *
     * @return {uint256} releasable amount of the whitelist
     *
     */
    function calculateReleasableAmount(uint256 _option, address _wallet)
        public
        view
        returns (uint256)
    {
        require(vestingPools[_option].active, "Vesting option is not existing");
        require(
            vestingPools[_option].whitelistPool[_wallet].active,
            "User is not in whitelist"
        );
        return
            calculateVestAmount(_option, _wallet).sub(
                vestingPools[_option].whitelistPool[_wallet].distributedAmount
            );
    }

    /**
     *
     * @dev calculate the total vested amount by the time
     *
     * @param {address} user wallet address
     *
     * @return {uint256} return vested amount
     *
     */
    function calculateVestAmount(uint256 _option, address _wallet)
        public
        view
        returns (uint256)
    {
        require(vestingPools[_option].active, "Vesting option is not existing");
        require(
            vestingPools[_option].whitelistPool[_wallet].active,
            "User is not in whitelist"
        );

        if (block.timestamp < vestingPools[_option].cliff) {
            return 0;
        } else if (
            block.timestamp >=
            vestingPools[_option].start.add(vestingPools[_option].duration) ||
            vestingPools[_option].whitelistPool[_wallet].revoke
        ) {
            return vestingPools[_option].whitelistPool[_wallet].dcbAmount;
        } else {
            return
                vestingPools[_option]
                    .whitelistPool[_wallet]
                    .dcbAmount
                    .mul(block.timestamp.sub(vestingPools[_option].cliff))
                    .div(vestingPools[_option].duration);
        }
    }

    /**
     *
     * @dev allow the owner to revoke the vesting
     *
     */
    function revoke(uint256 _option, address _wallet) public onlyOwner {
        require(vestingPools[_option].active, "Vesting option is not existing");
        require(
            vestingPools[_option].whitelistPool[_wallet].active,
            "User is not in whitelist"
        );
        require(vestingPools[_option].revocable, "it is not able to revoke");
        require(
            !vestingPools[_option].whitelistPool[_wallet].revoke,
            "already revoked"
        );

        vestingPools[_option].whitelistPool[_wallet].revoke = true;

        emit Revoked(_wallet);
    }

    /**
     *
     * @dev allow the owner to disable the vesting
     *
     * User will not be able to claim his tokens, but claimable balance remains unchanged
     * May require an enable function along to reinstate users claim
     *
     */
    function disable(uint256 _option, address _wallet) public onlyOwner {
        require(vestingPools[_option].active, "Vesting option does not exist");
        require(
            vestingPools[_option].whitelistPool[_wallet].active,
            "User is not in whitelist"
        );
        require(
            !vestingPools[_option].whitelistPool[_wallet].disabled,
            "User is already disabled"
        );

        vestingPools[_option].whitelistPool[_wallet].disabled = true;

        emit Disabled(_wallet);
    }

    /**
     *
     * @dev Allow owner to transfer decubate token from contract
     *
     * @param {address} contract address of corresponding token
     * @param {uint256} amount of token to be transferred
     *
     * This is a generalized function which can be used to transfer any accidentally
     * sent (including DCB) out of the contract to wowner
     *
     */
    function transferDCB(IERC20 _token, uint256 _amount)
        external
        onlyOwner
        returns (bool)
    {
        bool success = _token.transfer(address(owner()), _amount);
        return success;
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
    function getTotalToken(IERC20 _token) external view returns (uint256) {
        return _token.balanceOf(address(this));
    }

    function hasWhitelist(uint256 _option, address _wallet)
        external
        view
        returns (bool)
    {
        require(vestingPools[_option].active, "Vesting option is not existing");
        return vestingPools[_option].whitelistPool[_wallet].active;
    }
}
