require("@nomiclabs/hardhat-waffle");
require('dotenv').config();
require("@nomiclabs/hardhat-etherscan");
require('./tasks/deployments/deploy-bridgerton')
require('./tasks/deployments/deploy-vault')
require('./solidity-coverage')
/*
To run a script on a fork open a terminal within this repo and run "npx hardhat node --fork YOUR_FULL_MORALIS_URL"
Then open a new terminal in this repo and run "npx hardhat run SCRIPT_TO_RUN --network localhost"
*/

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
// task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
//   const accounts = await hre.ethers.getSigners();

//   for (const account of accounts) {
//     console.log(account.address);
//   }
// });
// To learn how to create your own go to
// https://hardhat.org/guides/create-task.html


// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more


const moralisKey = process.env.MORALIS_KEY || '';
const account = process.env.PRIV_KEY || '';

module.exports = {
  solidity: {
    version: "0.8.10",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200,
      },
    },
  },
  networks: {
    hardhat: {
    },
    rinkeby: {
      url: `https://speedy-nodes-nyc.moralis.io/${moralisKey}/eth/rinkeby`,
      accounts: [account]
    },
    localhost: {
      url: 'http://127.0.0.1:8545/',
      gasPrice: 225000000000,
      timeout: 200000,
    },
    polygon: {
      url: `https://speedy-nodes-nyc.moralis.io/${moralisKey}/polygon/mainnet`,
      chainId: 137,
      gasPrice: 50000000000,
      accounts: [account],
    },
    mumbai: {
      url: `https://speedy-nodes-nyc.moralis.io/${moralisKey}/polygon/mumbai`,
      chainId: 80001,
      gasPrice: 14000000000,
      accounts: [account],
    },
    opera: {
      url: `https://speedy-nodes-nyc.moralis.io/${moralisKey}/fantom/mainnet`,
      chainId: 250,
      gasPrice: 2000000000,
      accounts: [account],
    },
    operaTestnet: {
      url: "https://rpc.testnet.fantom.network",
      chainId: 4002,
      //gasPrice: 2000000000,
      accounts: [account],
    },
    avalanche: {
      url: `https://speedy-nodes-nyc.moralis.io/${moralisKey}/avalanche/mainnet`,
      gasPrice: 35000000000,
      chainId: 43114,
      accounts: [account],
    },
    fuji: {
      url: `https://speedy-nodes-nyc.moralis.io/${moralisKey}/avalanche/testnet`,
      chainId: 43113,
      gasPrice: 225000000000,
      accounts: [account],
    },
    arbitrum: {
      url: `https://speedy-nodes-nyc.moralis.io/${moralisKey}/arbitrum/mainnet`,
      chainId: 42161,
      gasPrice: 600000000,
      accounts: [account],
    },
    arbitrumRinkebyTestnet: {
      url: `https://speedy-nodes-nyc.moralis.io/${moralisKey}/arbitrum/testnet`,
      chainId: 421611,
      gasPrice: 600000000,
      accounts: [account],
    },
  },
  etherscan: {
    apiKey: process.env.ETHERSCAN_KEY
  }
};
