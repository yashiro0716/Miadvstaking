# AD2 Staking contract (World Chain)

This branch adds a separate staking contract for ADV2.0 (AD2). It does not deploy contracts, move funds, or enable the existing ADV rewards app.

## Rules
- Intended chain: World Chain Mainnet, chain ID 480.
- Token: ADV2.0 (AD2), expected fixed supply 2,000,000 and 18 decimals. Verify the token's deployed address and decimals before deployment.
- Staking contract is separate from the ERC-20 token.
- Fixed simple APR: 20% (2,000 basis points), matching the previously discussed staking rate. Rewards are paid in AD2 from a separately funded reserve.
- Users may withdraw principal at any time. Pausing stops new deposits only; it does not disable withdrawals or reward claims.
- Contract has no owner function to withdraw user principal or sweep AD2.
- Reward claims revert if the AD2 balance beyond all accounted principal cannot cover the reward. This avoids spending principal as rewards.
- The deployer must separately fund the staking contract with reward AD2. A 20% APR is not a guarantee of solvency; rewards must be budgeted and tested.

## Tests
Run with Foundry:
```sh
forge test --match-path test/AD2Staking.t.sol -vv
```
These tests are added but have not been run in this environment. They are not an independent security audit.

## Deployment status
Not deployed. No staking contract address exists in this branch. Do not use on mainnet until tests pass, token address/decimals are verified on-chain, the reserve is funded, and independent security review is complete.
