require("@nomiclabs/hardhat-waffle");
//must create a .env file with the variable PRIVATE_KEY. Usage: process.env.PRIVATE_KEY
require('dotenv').config()

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "polygon",
  networks: {                     /* All Networks specified here are test networks */
    hardhat: {
    },
    polygon: {
      url: "https://rpc-mumbai.matic.today",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 80001,
      //explorer https://mumbai.polygonscan.com/
    },
    avalanche: {
      url: "https://api.avax-test.network/ext/bc/C/rpc",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 43113
      //explorer https://testnet.snowtrace.io/
    },
    fantom: {
      url: "https://rpc.testnet.fantom.network/",
      accounts: [process.env.PRIVATE_KEY],
      chainId: 0xfa2 //4002 in hex
      //explorer https://explorer.testnet.fantom.network/
    }
  },
  solidity: "0.8.10",
};
