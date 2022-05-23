# Savor Cross Chain Yield Aggregator

This repo includes the contracts for the Savor Cross chain yield aggregaor being submitted for the Chainklink spring 22 hackathon.

Savor strives to be the first cross chain yield aggregator. With one deposit on any of the supported chain users are automatically earning the highest yields available across all supported chains.

## Setup

This repository is built using hardhat.

To Setup:
```
    1. Clone Repo on to your local device
    2. run "npm install"  to install dependencies
    3. Create an .env file and copy envexample in filling in the info for each variable
    4. Run "npx hardhat compile"
```
## Architecture

The master vault (SavorVault.sol) uses the ERC4626 token standard and is an adaptation of the Rari Capital vaults that can be found here. https://github.com/Rari-Capital/vaults.

The Bridgerton.sol contract utilizies the Stargate router to send funds between multiple chains.

The Strategies for each vault (StratExample.sol) are adapted from Yearn.Finance strategies used for their vaults.

![alt text](/misc/vaultArch.png)

## Tests


## Deploy

All contracts can be deployed through the pre-made npm commands to any supported network.

simply run the command in order of "contract:network:deploy"

EX: "npm run bridgerton:rinkeby:deploy" will deploy the bridgerton contract and verify the contract on etherscan if the etherscan key is provided in the .env

You can test the deployment tasks on a local fork by inserting localhost in the network spot while a fork of the desired chain is running on your local device at http://127.0.0.1:8545/.

All deployments are saved in deployments.json after deployed to be used in the other tasks.
---- deployments.txt is the officail addresses and should not be changed ----

Bridgerton contract should be deployed first followed by the Vault then any Strategies can be added

The deploy-strategy task will need to updated based on the contrusctor parameters for the strategy being deployed

## Cobntributing

To submit contributions create a fork on your own Github with all changes proposed and submit a Pull Request on to the main branch

Pull Requests will be reviewed by team members and merged if approved

Make sure to 'Git Pull origin main' before working on any updates to make sure your branch is up to date

To make a new strategy simply copy the StratExample.sol into a new file and fill in the functions listed based on the strategys needs.

## Hardhat
Try running some of the following tasks:

```shell
npx hardhat accounts
npx hardhat compile
npx hardhat clean
npx hardhat test
npx hardhat node
node scripts/sample-script.js
npx hardhat help
```

For more information on Hardhat https://hardhat.org/getting-started/