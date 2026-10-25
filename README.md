# ADV Rewards — World App Mini App

Responsive Next.js interface for daily ADV rewards on World Chain. The web frontend can be deployed, but real claims remain disabled until an ADVRewards contract is deployed, funded, verified and configured.

## Configuration

Copy `.env.example` to `.env.local` and set:

- `NEXT_PUBLIC_CHAIN_ID=480`
- `NEXT_PUBLIC_ADV_TOKEN` to the verified ADV ERC-20 address
- `NEXT_PUBLIC_REWARDS_CONTRACT` to the deployed ADVRewards contract address

Then run `npm install && npm run dev`. Never put private keys in `NEXT_PUBLIC_*` variables.

## World App

MiniKit 2.0 aligns Mini Apps with EIP-1193, so the app uses a wallet provider exposed as `window.ethereum`. Test in World App and follow the current official Mini Apps registration process: https://docs.world.org/mini-apps

## Safety

This frontend does not mint tokens and cannot pay rewards without a real contract. Confirm token address and decimals on Worldscan, test the contract on testnet, have it independently reviewed, then deploy and fund it. The current daily limit is per wallet address, not per verified person. A real deployment is not an official World affiliation.
