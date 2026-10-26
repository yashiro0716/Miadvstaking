# ADV2.0 (AD2) and staking

## Intended deployment
- Network: World Chain Mainnet, chain ID 480.
- Token contract: `contracts/ADV20.sol`, fixed supply 2,000,000 AD2 with 18 decimals.
- Staking contract: `contracts/AD2Staking.sol`, separate from the token contract.
- Staking rewards: simple 20% APR, paid in AD2 only from a separately funded reserve.
- User principal is accounted for separately and cannot be owner-withdrawn. Emergency pause affects deposits only.

## Current status
Code is committed to the feature branch and a draft pull request is open. No contracts have been deployed and no funds have been moved. Do not configure production app addresses until contracts are deployed and independently verified on World Chain.

## Validation
A GitHub Actions workflow runs `forge test -vvv` and `npm run build` for pushes and pull requests. Workflow results must be reviewed after GitHub executes the workflow. Local/manual tests must not be described as passing until a run confirms it.

## Mainnet checklist
1. Review token and staking code and run Foundry tests.
2. Independently audit staking and token contracts; verify token decimals and constructor supply.
3. Deploy AD2 token on chain 480 from an authorized wallet and verify source code.
4. Decide a documented reward-reserve budget before opening staking. A 20% APR can exhaust the reserve; it is not a guaranteed return.
5. Deploy staking with the verified AD2 token address.
6. Fund the reward reserve separately from user principal.
7. Set Vercel public variables `NEXT_PUBLIC_CHAIN_ID=480`, `NEXT_PUBLIC_AD2_TOKEN`, and `NEXT_PUBLIC_AD2_STAKING_CONTRACT` to verified addresses, then deploy the frontend.
8. Test connect, approve, stake, withdraw, and claim in a test environment and inside World App before production use.
