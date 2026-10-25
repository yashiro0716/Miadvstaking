// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IERC20Rewards {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 value) external returns (bool);
}

/// @title ADVRewards
/// @notice Fixed-amount ADV rewards with a 24-hour cooldown per wallet.
/// @dev The deployer must fund this contract with ADV tokens before claims can succeed.
contract ADVRewards {
    error NotOwner();
    error WrongChain(uint256 actualChainId);
    error ZeroAddress();
    error ZeroAmount();
    error ClaimsPaused();
    error CooldownActive(uint256 availableAt);
    error InsufficientRewards();
    error TokenTransferFailed();
    error CannotRescueRewardToken();

    IERC20Rewards public immutable token;
    uint256 public immutable rewardAmount;
    address public owner;
    bool public paused;
    mapping(address => uint256) public nextClaimAt;

    event RewardClaimed(address indexed account, uint256 amount, uint256 nextAvailableAt);
    event PausedChanged(bool paused);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    event ForeignTokenRescued(address indexed token, address indexed to, uint256 amount);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor(address tokenAddress, uint256 rewardAmount_) {
        if (block.chainid != 480) revert WrongChain(block.chainid);
        if (tokenAddress == address(0)) revert ZeroAddress();
        if (rewardAmount_ == 0) revert ZeroAmount();
        token = IERC20Rewards(tokenAddress);
        rewardAmount = rewardAmount_;
        owner = msg.sender;
        emit OwnershipTransferred(address(0), msg.sender);
    }

    function claim() external {
        if (paused) revert ClaimsPaused();
        uint256 availableAt = nextClaimAt[msg.sender];
        if (availableAt != 0 && block.timestamp < availableAt) revert CooldownActive(availableAt);
        if (token.balanceOf(address(this)) < rewardAmount) revert InsufficientRewards();

        uint256 nextAvailableAt = block.timestamp + 1 days;
        nextClaimAt[msg.sender] = nextAvailableAt;

        (bool ok, bytes memory data) = address(token).call(
            abi.encodeWithSelector(IERC20Rewards.transfer.selector, msg.sender, rewardAmount)
        );
        if (!ok || (data.length != 0 && !abi.decode(data, (bool)))) revert TokenTransferFailed();
        emit RewardClaimed(msg.sender, rewardAmount, nextAvailableAt);
    }

    function setPaused(bool value) external onlyOwner {
        paused = value;
        emit PausedChanged(value);
    }

    function transferOwnership(address newOwner) external onlyOwner {
        if (newOwner == address(0)) revert ZeroAddress();
        emit OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }

    /// @notice Recover tokens accidentally sent here, but never the reward token itself.
    function rescueForeignToken(address foreignToken, address to, uint256 amount) external onlyOwner {
        if (foreignToken == address(token)) revert CannotRescueRewardToken();
        if (to == address(0)) revert ZeroAddress();
        (bool ok, bytes memory data) = foreignToken.call(
            abi.encodeWithSignature("transfer(address,uint256)", to, amount)
        );
        if (!ok || (data.length != 0 && !abi.decode(data, (bool)))) revert TokenTransferFailed();
        emit ForeignTokenRescued(foreignToken, to, amount);
    }
}
