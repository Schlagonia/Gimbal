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

  const usdc = '0xc2132d05d31c914a87c6611c10748aeb04b58e8f'              //Underlying USDC 0x817436a076060D158204d955E5403b6Ed0A5fac0
  const stargate = '0x817436a076060D158204d955E5403b6Ed0A5fac0'          // Stargate Testnet Router https://mumbai.polygonscan.com/address/0x817436a076060D158204d955E5403b6Ed0A5fac0
  const tenth = '100000000000000000'

  let gasPrice = await provider.getGasPrice()
  const params = { gasLimit: String("1500000000"), gasPrice: gasPrice }

  //Deploy Bridgerton First
  const Bridgerton = await ethers.getContractFactory('Bridgerton')
  const bridgerton = await Bridgerton.connect(wallet).deploy(
    stargate

  )
  await bridgerton.deployed()


  //Then Deploy Vault
  const Vault = await ethers.getContractFactory("SavorVault");
  const vault = await Vault.connect(wallet).deploy(
    usdc,  //Underlying USDC 
    bridgerton.address,   // Brigerton
    wallet.address,   //Keeper,
    { params }
  )

  await vault.deployed()
  console.log("Vault Deployed: ", vault.address)

  // //set the fee percent
  // Sets performance fee to 10%

  await vault.connect(wallet).setFeePercent(tenth)
  console.log("Target fee Percent set")
  // //Set Target Float
  await vault.connect(wallet).setTargetFloatPercent(tenth)
  console.log("Targe Float Set")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
