// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal ERC-20 interface. Uses low-level safe transfers to support standard ERC-20 tokens.
interface IAD2Token {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

/// @title AD2Staking
/// @notice Non-custodial-style accounting for staking ADV2.0 (AD2) with a fixed 20% simple APR.
/// @dev Rewards are paid only from surplus AD2 held by this contract. Principal is always accounted separately.
///      Fund the contract with AD2 in addition to user deposits before promising rewards.
contract AD2Staking {
    uint256 public constant APR_BPS = 2_000;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant YEAR = 365 days;

    IAD2Token public immutable stakingToken;
    address public owner;
    bool public depositsPaused;
    uint256 public totalStaked;
    uint256 private _entered = 1;

    struct Position {
        uint256 amount;
        uint256 accruedRewards;
        uint256 lastUpdate;
    }
    mapping(address => Position) public positions;

    error ZeroAddress();
    error ZeroAmount();
    error NotOwner();
    error DepositsArePaused();
    error InsufficientStake();
    error InsufficientRewardReserve();
    error TokenCallFailed();
    error ReentrantCall();

    event Staked(address indexed account, uint256 amount);
    event Withdrawn(address indexed account, uint256 amount);
    event RewardClaimed(address indexed account, uint256 amount);
    event DepositPauseChanged(bool paused);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    modifier nonReentrant() {
        if (_entered != 1) revert ReentrantCall();
        _entered = 2;
        _;
        _entered = 1;
    }

    constructor(address tokenAddress) {
        if (tokenAddress == address(0)) revert ZeroAddress();
        stakingToken = IAD2Token(tokenAddress);
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function stake(uint256 amount) external nonReentrant {
        if (depositsPaused) revert DepositsArePaused();
        if (amount == 0) revert ZeroAmount();
        _checkpoint(msg.sender);
        _safeTransferFrom(msg.sender, address(this), amount);
        positions[msg.sender].amount += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        Position storage p = positions[msg.sender];
        if (amount > p.amount) revert InsufficientStake();
        _checkpoint(msg.sender);
        p.amount -= amount;
        totalStaked -= amount;
        _safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() external nonReentrant returns (uint256 amount) {
        _checkpoint(msg.sender);
        Position storage p = positions[msg.sender];
        amount = p.accruedRewards;
        if (amount == 0) revert ZeroAmount();
        // Balance above totalStaked is the reward reserve; user principal cannot be spent on rewards.
        if (stakingToken.balanceOf(address(this)) < totalStaked + amount) {
            revert InsufficientRewardReserve();
        }
        p.accruedRewards = 0;
        _safeTransfer(msg.sender, amount);
        emit RewardClaimed(msg.sender, amount);
    }

    function pendingRewards(address account) external view returns (uint256) {
        Position storage p = positions[account];
        if (p.amount == 0 || p.lastUpdate == 0) return p.accruedRewards;
        uint256 elapsed = block.timestamp - p.lastUpdate;
        return p.accruedRewards + (p.amount * APR_BPS * elapsed) / (BPS_DENOMINATOR * YEAR);
    }

    function rewardReserve() external view returns (uint256) {
        uint256 balance = stakingToken.balanceOf(address(this));
        return balance > totalStaked ? balance - totalStaked : 0;
    }

    /// @notice Emergency control only stops new deposits; withdrawals and claims remain available.
    function setDepositsPaused(bool value) external onlyOwner {
        depositsPaused = value;
        emit DepositPauseChanged(value);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function _checkpoint(address account) internal {
        Position storage p = positions[account];
        if (p.lastUpdate != 0 && p.amount != 0) {
            uint256 elapsed = block.timestamp - p.lastUpdate;
            p.accruedRewards += (p.amount * APR_BPS * elapsed) / (BPS_DENOMINATOR * YEAR);
        }
        p.lastUpdate = block.timestamp;
    }

    function _safeTransfer(address to, uint256 amount) internal {
        (bool ok, bytes memory data) = address(stakingToken).call(
            abi.encodeWithSelector(IAD2Token.transfer.selector, to, amount)
        );
        if (!ok || (data.length != 0 && (data.length < 32 || !abi.decode(data, (bool))))) {
            revert TokenCallFailed();
        }
    }

    function _safeTransferFrom(address from, address to, uint256 amount) internal {
        (bool ok, bytes memory data) = address(stakingToken).call(
            abi.encodeWithSelector(IAD2Token.transferFrom.selector, from, to, amount)
        );
        if (!ok || (data.length != 0 && (data.length < 32 || !abi.decode(data, (bool))))) {
            revert TokenCallFailed();
        }
    }
}
