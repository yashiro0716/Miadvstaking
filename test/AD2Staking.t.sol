// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/AD2Staking.sol";

interface VmAD2 {
    function warp(uint256) external;
    function prank(address) external;
    function expectRevert(bytes calldata) external;
}

contract MockAD2 {
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    function mint(address to, uint256 amount) external { balanceOf[to] += amount; }
    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }
    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        require(allowance[from][msg.sender] >= amount, "allowance");
        require(balanceOf[from] >= amount, "balance");
        allowance[from][msg.sender] -= amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract AD2StakingTest {
    VmAD2 private constant vm = VmAD2(address(uint160(uint256(keccak256("hevm cheat code")))));
    MockAD2 private token;
    AD2Staking private staking;
    address private alice = address(0xA11CE);
    address private bob = address(0xB0B);

    function setUp() public {
        token = new MockAD2();
        staking = new AD2Staking(address(token));
        token.mint(alice, 1_000 ether);
        token.mint(address(staking), 1_000 ether); // separate rewards reserve
        vm.prank(alice);
        token.approve(address(staking), type(uint256).max);
    }

    function testStakeAndWithdrawPrincipal() public {
        vm.prank(alice);
        staking.stake(100 ether);
        require(staking.totalStaked() == 100 ether, "total stake");
        vm.prank(alice);
        staking.withdraw(40 ether);
        require(token.balanceOf(alice) == 940 ether, "withdraw balance");
        require(staking.totalStaked() == 60 ether, "remaining stake");
    }

    function testAccruesFixedTwentyPercentAPR() public {
        vm.prank(alice);
        staking.stake(100 ether);
        vm.warp(block.timestamp + 365 days);
        require(staking.pendingRewards(alice) == 20 ether, "APR should be 20 percent");
    }

    function testRewardsCannotConsumePrincipal() public {
        vm.prank(alice);
        staking.stake(100 ether);
        vm.warp(block.timestamp + 365 days);
        // Reserve is 1,000 AD2 and can cover the 20 AD2 reward.
        vm.prank(alice);
        staking.claimRewards();
        require(token.balanceOf(alice) == 920 ether, "reward paid");
        require(staking.totalStaked() == 100 ether, "principal accounting changed");
    }

    function testCannotWithdrawMoreThanStaked() public {
        vm.prank(alice);
        staking.stake(10 ether);
        vm.expectRevert(abi.encodeWithSelector(AD2Staking.InsufficientStake.selector));
        vm.prank(alice);
        staking.withdraw(11 ether);
    }

    function testPauseOnlyStopsDeposits() public {
        staking.setDepositsPaused(true);
        vm.expectRevert(abi.encodeWithSelector(AD2Staking.DepositsArePaused.selector));
        vm.prank(alice);
        staking.stake(1 ether);
    }

    function testCannotClaimWhenRewardReserveInsufficient() public {
        // Deploy a fresh contract with no reward reserve.
        AD2Staking emptyReserve = new AD2Staking(address(token));
        vm.prank(alice);
        token.approve(address(emptyReserve), type(uint256).max);
        vm.prank(alice);
        emptyReserve.stake(10 ether);
        vm.warp(block.timestamp + 365 days);
        vm.expectRevert(abi.encodeWithSelector(AD2Staking.InsufficientRewardReserve.selector));
        vm.prank(alice);
        emptyReserve.claimRewards();
    }
}
