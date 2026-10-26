// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "../contracts/AD2Staking.sol";

interface VmDeployAD2Staking {
    function envAddress(string calldata name) external returns (address);
    function startBroadcast() external;
    function stopBroadcast() external;
}

interface IAD2Metadata {
    function decimals() external view returns (uint8);
    function symbol() external view returns (string memory);
    function totalSupply() external view returns (uint256);
}

/// @notice Deploys AD2 staking on World Chain Mainnet after the AD2 token is verified.
/// @dev Requires AD2_TOKEN_ADDRESS and an authorized Foundry signer. Does not fund rewards.
contract DeployAD2Staking {
    error WrongNetwork(uint256 actualChainId);
    error InvalidToken();
    error UnexpectedTokenMetadata();
    VmDeployAD2Staking private constant vm = VmDeployAD2Staking(address(uint160(uint256(keccak256("hevm cheat code")))));

    function run() external returns (AD2Staking staking) {
        if (block.chainid != 480) revert WrongNetwork(block.chainid);
        address token = vm.envAddress("AD2_TOKEN_ADDRESS");
        if (token == address(0) || token.code.length == 0) revert InvalidToken();
        IAD2Metadata metadata = IAD2Metadata(token);
        if (metadata.decimals() != 18 || keccak256(bytes(metadata.symbol())) != keccak256(bytes("AD2")) || metadata.totalSupply() != 2_000_000 ether) {
            revert UnexpectedTokenMetadata();
        }
        vm.startBroadcast();
        staking = new AD2Staking(token);
        vm.stopBroadcast();
    }
}
