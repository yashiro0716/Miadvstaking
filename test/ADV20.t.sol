// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/ADV20.sol";

interface VmToken {
    function prank(address) external;
    function expectRevert(bytes calldata) external;
}

contract ADV20Test {
    VmToken private constant vm = VmToken(address(uint160(uint256(keccak256("hevm cheat code")))));
    ADV20 private token;
    address private alice = address(0xA11CE);
    address private bob = address(0xB0B);

    function setUp() public { token = new ADV20(); }

    function testFixedSupplyMintedToDeployer() public {
        require(token.totalSupply() == 2_000_000 ether, "wrong supply");
        require(token.balanceOf(address(this)) == 2_000_000 ether, "wrong initial holder");
        require(token.decimals() == 18, "wrong decimals");
    }

    function testTransfersAndAllowances() public {
        token.transfer(alice, 100 ether);
        vm.prank(alice);
        token.approve(address(this), 30 ether);
        token.transferFrom(alice, bob, 30 ether);
        require(token.balanceOf(alice) == 70 ether, "alice balance");
        require(token.balanceOf(bob) == 30 ether, "bob balance");
        require(token.totalSupply() == 2_000_000 ether, "supply changed");
    }

    function testCannotTransferMoreThanBalance() public {
        vm.expectRevert(abi.encodeWithSelector(ADV20.InsufficientBalance.selector));
        token.transfer(alice, 2_000_001 ether);
    }

    function testCannotMintAfterDeployment() public {
        (bool ok,) = address(token).call(abi.encodeWithSignature("mint(address,uint256)", alice, 1 ether));
        require(!ok, "unexpected mint function");
        require(token.totalSupply() == 2_000_000 ether, "supply changed");
    }
}
