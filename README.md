# ADV Rewards — World Chain Mini App

Next.js interface for daily ADV token rewards on World Chain (chain ID 480).

## Current status
- The frontend is deployed on Vercel.
- Claims remain disabled until `NEXT_PUBLIC_REWARDS_CONTRACT` is set to the verified deployment address.
- Contract source, a Foundry test suite, and a deployment script are included here. Mainnet deployment and funding require an authorized wallet transaction.
- Never share a private key or seed phrase in chat.

## Contract
`contracts/ADVRewards.sol` pays a fixed raw-token amount once per wallet every 24 hours. It has an owner pause switch; the owner cannot withdraw the ADV reward token. Accidental non-ADV tokens can be rescued.

The reward amount is passed in the token's smallest units. For an 18-decimal ADV token, 25 ADV is `25000000000000000000`. Verify the token address and decimals on World Chain before deployment.

## Test
Install Foundry, then run:
```sh
forge test
```

## Deploy (only after reviewing the source and verifying token decimals)
Set environment variables locally; do not commit them:
```sh
export ADV_TOKEN_ADDRESS=0x6d13932b942de3ee93d0e519be41b9ef46cf7fda
export ADV_REWARD_AMOUNT=25000000000000000000
forge script script/DeployADVRewards.s.sol:DeployADVRewards --rpc-url https://worldchain-mainnet.g.alchemy.com/public --broadcast
```
The example amount assumes 18 decimals; do not use it unless decimals are confirmed. The deployer needs ETH for gas. After deployment, fund the contract with ADV and test a small claim before enabling claims.

## Vercel
Configure these public environment variables and redeploy:
- `NEXT_PUBLIC_CHAIN_ID=480`
- `NEXT_PUBLIC_ADV_TOKEN=0x6d13932b942de3ee93d0e519be41b9ef46cf7fda`
- `NEXT_PUBLIC_REWARDS_CONTRACT=<deployed contract address>`

## World App
Register the production URL and required Mini App metadata in the World Developer Portal after testing wallet behavior inside World App.
