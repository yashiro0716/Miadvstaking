// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/ADVRewards.sol";

interface VmDeploy {
    function envAddress(string calldata name) external returns (address);
    function envUint(string calldata name) external returns (uint256);
    function startBroadcast() external;
    function stopBroadcast() external;
}

contract DeployADVRewards {
    VmDeploy private constant vm = VmDeploy(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external returns (ADVRewards deployed) {
        address token = vm.envAddress("ADV_TOKEN_ADDRESS");
        uint256 rewardAmount = vm.envUint("ADV_REWARD_AMOUNT");
        vm.startBroadcast();
        deployed = new ADVRewards(token, rewardAmount);
        vm.stopBroadcast();
    }
}
