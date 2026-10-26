# AD2 deployment scripts

These scripts are preparation only; they have not been executed.

## 1. Deploy the fixed-supply token
Run only with a wallet you control and understand:
```sh
forge script script/DeployADV20.s.sol:DeployADV20 --rpc-url https://worldchain-mainnet.g.alchemy.com/public --broadcast
```
This script refuses to run on any chain except World Chain Mainnet (480). The deployer receives all 2,000,000 AD2. Verify the deployed source and constructor transaction on Worldscan before proceeding.

## 2. Deploy the staking contract
After verifying the token contract:
```sh
export AD2_TOKEN_ADDRESS=0xYOUR_VERIFIED_AD2_TOKEN_ADDRESS
forge script script/DeployAD2Staking.s.sol:DeployAD2Staking --rpc-url https://worldchain-mainnet.g.alchemy.com/public --broadcast
```
The script checks chain ID, code at the token address, symbol, decimals, and total supply. It does not move or fund tokens.

## 3. Funding and enabling the app
Before enabling staking, decide the maximum rewards budget. Transfer that amount of AD2 from the token holder to the staking contract as a reward reserve, separately from users' principal. Test a small stake/withdraw/claim sequence first. Only then configure the Vercel variables NEXT_PUBLIC_CHAIN_ID=480, NEXT_PUBLIC_AD2_TOKEN, and NEXT_PUBLIC_AD2_STAKING_CONTRACT.

Never put seed phrases or private keys in repository files, chat, or public variables. Use a local secure signer / hardware wallet flow. A successful script broadcast is not a substitute for an independent security review.
