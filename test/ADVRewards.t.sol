// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/ADVRewards.sol";

interface Vm {
    function warp(uint256) external;
    function prank(address) external;
    function expectRevert(bytes calldata) external;
}

contract MockADV {
    string public constant name = "ADV";
    string public constant symbol = "ADV";
    uint8 public constant decimals = 18;
    mapping(address => uint256) public balanceOf;

    function mint(address to, uint256 amount) external { balanceOf[to] += amount; }

    function transfer(address to, uint256 amount) external returns (bool) {
        require(balanceOf[msg.sender] >= amount, "balance");
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract ADVRewardsTest {
    Vm private constant vm = Vm(address(uint160(uint256(keccak256("hevm cheat code")))));
    MockADV private token;
    ADVRewards private rewards;
    address private alice = address(0xA11CE);
    address private bob = address(0xB0B);

    function setUp() public {
        token = new MockADV();
        rewards = new ADVRewards(address(token), 25 ether);
        token.mint(address(rewards), 1_000 ether);
    }

    function testClaimPaysFixedRewardAndSetsCooldown() public {
        vm.prank(alice);
        rewards.claim();
        require(token.balanceOf(alice) == 25 ether, "wrong reward");
        require(rewards.nextClaimAt(alice) == block.timestamp + 1 days, "wrong cooldown");
    }

    function testCannotClaimTwiceWithin24Hours() public {
        vm.prank(alice);
        rewards.claim();
        vm.expectRevert(abi.encodeWithSelector(ADVRewards.CooldownActive.selector, block.timestamp + 1 days));
        vm.prank(alice);
        rewards.claim();
    }

    function testCanClaimAgainAfter24Hours() public {
        vm.prank(alice);
        rewards.claim();
        vm.warp(block.timestamp + 1 days);
        vm.prank(alice);
        rewards.claim();
        require(token.balanceOf(alice) == 50 ether, "second reward missing");
    }

    function testDifferentWalletsClaimIndependently() public {
        vm.prank(alice);
        rewards.claim();
        vm.prank(bob);
        rewards.claim();
        require(token.balanceOf(alice) == 25 ether, "alice reward missing");
        require(token.balanceOf(bob) == 25 ether, "bob reward missing");
    }

    function testPausedClaimsRevert() public {
        rewards.setPaused(true);
        vm.expectRevert(abi.encodeWithSelector(ADVRewards.ClaimsPaused.selector));
        vm.prank(alice);
        rewards.claim();
    }

    function testInsufficientReserveReverts() public {
        token = new MockADV();
        rewards = new ADVRewards(address(token), 25 ether);
        vm.expectRevert(abi.encodeWithSelector(ADVRewards.InsufficientRewards.selector));
        vm.prank(alice);
        rewards.claim();
    }

    function testOnlyOwnerCanPause() public {
        vm.expectRevert(abi.encodeWithSelector(ADVRewards.NotOwner.selector));
        vm.prank(alice);
        rewards.setPaused(true);
    }
}
