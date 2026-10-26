// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/ADV20.sol";

interface VmDeployAD2 {
    function startBroadcast() external;
    function stopBroadcast() external;
}

/// @notice Deploys the fixed-supply AD2 token only on World Chain Mainnet (chain ID 480).
/// @dev Requires an authorized Foundry signer and ETH for gas. This script does not fund staking.
contract DeployADV20 {
    error WrongNetwork(uint256 actualChainId);
    VmDeployAD2 private constant vm = VmDeployAD2(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external returns (ADV20 token) {
        if (block.chainid != 480) revert WrongNetwork(block.chainid);
        vm.startBroadcast();
        token = new ADV20();
        vm.stopBroadcast();
    }
}
