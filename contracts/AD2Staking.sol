// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

/// @notice Minimal ERC-20 interface for the standalone AD2 staking contract.
interface IAD2Token {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function transferFrom(address from, address to, uint256 amount) external returns (bool);
}

/// @title AD2Staking
/// @notice Fixed target APR of 20%, paid only when the funded reward reserve can cover it.
/// @dev Rewards stop accruing when free reserve is exhausted. Principal and already-allocated
///      reward liabilities are excluded from the reserve, so the same tokens cannot be promised twice.
contract AD2Staking {
    uint256 public constant APR_BPS = 2_000;
    uint256 public constant BPS_DENOMINATOR = 10_000;
    uint256 public constant YEAR = 365 days;
    uint256 private constant PRECISION = 1e18;

    IAD2Token public immutable stakingToken;
    address public owner;
    bool public depositsPaused;
    uint256 public totalStaked;
    uint256 public totalRewardsAccruedUnclaimed;
    uint256 public rewardPerTokenStored;
    uint256 public lastUpdateTime;
    uint256 private _entered = 1;

    struct Position {
        uint256 amount;
        uint256 accruedRewards;
    }
    mapping(address => Position) public positions;
    mapping(address => uint256) public userRewardPerTokenPaid;

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
        lastUpdateTime = block.timestamp;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function stake(uint256 amount) external nonReentrant {
        if (depositsPaused) revert DepositsArePaused();
        if (amount == 0) revert ZeroAmount();
        _updateGlobal();
        _checkpointUser(msg.sender);
        uint256 beforeBalance = stakingToken.balanceOf(address(this));
        _safeTransferFrom(msg.sender, address(this), amount);
        uint256 received = stakingToken.balanceOf(address(this)) - beforeBalance;
        if (received != amount) revert TokenCallFailed();
        positions[msg.sender].amount += amount;
        totalStaked += amount;
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert ZeroAmount();
        _updateGlobal();
        _checkpointUser(msg.sender);
        Position storage p = positions[msg.sender];
        if (amount > p.amount) revert InsufficientStake();
        p.amount -= amount;
        totalStaked -= amount;
        _safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function claimRewards() external nonReentrant returns (uint256 amount) {
        _updateGlobal();
        _checkpointUser(msg.sender);
        Position storage p = positions[msg.sender];
        amount = p.accruedRewards;
        if (amount == 0) revert ZeroAmount();
        if (stakingToken.balanceOf(address(this)) < totalStaked + amount) {
            revert InsufficientRewardReserve();
        }
        p.accruedRewards = 0;
        totalRewardsAccruedUnclaimed -= amount;
        _safeTransfer(msg.sender, amount);
        emit RewardClaimed(msg.sender, amount);
    }

    function pendingRewards(address account) external view returns (uint256) {
        uint256 acc = rewardPerTokenStored;
        uint256 elapsed = block.timestamp - lastUpdateTime;
        if (elapsed != 0 && totalStaked != 0) {
            uint256 balance = stakingToken.balanceOf(address(this));
            uint256 liabilities = totalStaked + totalRewardsAccruedUnclaimed;
            uint256 available = balance > liabilities ? balance - liabilities : 0;
            uint256 emission = (totalStaked * APR_BPS * elapsed) / (BPS_DENOMINATOR * YEAR);
            if (emission > available) emission = available;
            if (emission != 0) {
                uint256 delta = (emission * PRECISION) / totalStaked;
                acc += delta;
            }
        }
        Position storage p = positions[account];
        return p.accruedRewards + (p.amount * (acc - userRewardPerTokenPaid[account])) / PRECISION;
    }

    /// @notice Unallocated reserve available for future reward accrual.
    function rewardReserve() external view returns (uint256) {
        uint256 balance = stakingToken.balanceOf(address(this));
        uint256 liabilities = totalStaked + totalRewardsAccruedUnclaimed;
        return balance > liabilities ? balance - liabilities : 0;
    }

    function setDepositsPaused(bool value) external onlyOwner {
        depositsPaused = value;
        emit DepositPauseChanged(value);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    function _updateGlobal() internal {
        uint256 elapsed = block.timestamp - lastUpdateTime;
        if (elapsed == 0) return;
        lastUpdateTime = block.timestamp;
        if (totalStaked == 0) return;

        uint256 balance = stakingToken.balanceOf(address(this));
        uint256 liabilities = totalStaked + totalRewardsAccruedUnclaimed;
        uint256 available = balance > liabilities ? balance - liabilities : 0;
        if (available == 0) return;

        uint256 emission = (totalStaked * APR_BPS * elapsed) / (BPS_DENOMINATOR * YEAR);
        if (emission > available) emission = available;
        if (emission == 0) return;

        uint256 delta = (emission * PRECISION) / totalStaked;
        uint256 allocated = (delta * totalStaked) / PRECISION;
        if (allocated == 0) return;
        rewardPerTokenStored += delta;
        totalRewardsAccruedUnclaimed += allocated;
    }

    function _checkpointUser(address account) internal {
        Position storage p = positions[account];
        uint256 paid = userRewardPerTokenPaid[account];
        uint256 current = rewardPerTokenStored;
        if (current != paid) {
            p.accruedRewards += (p.amount * (current - paid)) / PRECISION;
            userRewardPerTokenPaid[account] = current;
        }
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
