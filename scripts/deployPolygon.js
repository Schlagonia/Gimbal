const { ethers } = require("hardhat");
const hre = require("hardhat");
const { networks } = require('../hardhat.config')
//const { impersonateAddress } = require("../helpers/misc-utils");

//must create a .env file with the variable PRIVATE_KEY. Usage: process.env.PRIVATE_KEY
require('dotenv').config()


async function main() {

  const currentNetwork = networks.polygon.url
  console.log("Deploying to current network: ", currentNetwork)

  const provider = await new ethers.providers.JsonRpcProvider(currentNetwork)

  var wallet = await new ethers.Wallet.fromMnemonic(process.env.MNEMONIC, `m/44'/60'/0'/0/2`)
  wallet = wallet.connect(provider)
  const newBalance = await wallet.getBalance()

  console.log("Balance of this wallet is: ", newBalance.toString())

  console.log("Deployer address: ", wallet.address)
  const Vault = await ethers.getContractFactory("GimbalVault");
  const vault = await Vault.connect(wallet).deploy(
    '0xc2132d05d31c914a87c6611c10748aeb04b58e8f',  //Underlying USDC 0x817436a076060D158204d955E5403b6Ed0A5fac0
    wallet.address,                                //Keeper,
    '0x817436a076060D158204d955E5403b6Ed0A5fac0',  // Stargate Testnet Router https://mumbai.polygonscan.com/address/0x817436a076060D158204d955E5403b6Ed0A5fac0
    { gasLimit: String("1400000000"), gasPrice: String("1400000000") }
  )

  await vault.deployed()
  console.log("Vault Deployed: ", vault.address)

  // //set the fee percent

  // //Set Target Float

  // //Set harvest deplay and Harvest Window

  // //Initialize the Vault

  // console.log("Vault Ready to Go")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
