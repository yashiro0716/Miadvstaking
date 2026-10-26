# AD2 Staking contract — security hardening status

This is a separate development branch for the new ADV2.0 (AD2) token and staking design. It does not deploy contracts, move funds, or intentionally activate any earlier ADV staking project.

## Configuration
- Intended network: World Chain Mainnet, chain ID 480.
- Token: ADV2.0 (AD2), fixed supply 2,000,000 tokens with 18 decimals.
- Separate staking contract, target APR 20% (2,000 basis points).
- Principal withdrawals remain available even if new deposits are paused.
- No owner function withdraws user principal or sweeps tokens from the contract.

## Reward reserve hardening
- Reward accrual is limited by the free reserve after subtracting staked principal and already allocated-but-unclaimed reward liabilities.
- Once the free reserve is exhausted, additional rewards stop accruing until the contract receives more reserve tokens.
- A limited reserve is allocated proportionally across all stakers active during the relevant accrual interval; the same reserve is not promised repeatedly.
- Token transfers are checked for exact received amounts on deposits, so fee-on-transfer tokens are rejected.
- The 20% figure is a target rate, not a guaranteed return: realized rewards depend on available funding and rounding.

## Validation required
Run:
```sh
forge test -vvv
npm run build
```
Automated checks must pass on the exact commit intended for review. These checks are not a substitute for independent smart-contract security auditing or a live test in World App.

## Deployment status
Not deployed. No mainnet token or staking address has been verified for this new project. Do not deploy or configure production addresses until the exact code passes CI, the token and staking code receive independent review, the reward budget is decided, and an authorized wallet owner approves each deployment transaction. Never share a seed phrase or private key in chat.
