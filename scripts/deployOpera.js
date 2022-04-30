const { ethers } = require("hardhat");
const hre = require("hardhat");
const { networks } = require('../hardhat.config')
//const { impersonateAddress } = require("../helpers/misc-utils");

//must create a .env file with the variable PRIVATE_KEY. Usage: process.env.PRIVATE_KEY
require('dotenv').config()


async function main() {

  const stargateRouter = '0xa73b0a56B29aD790595763e71505FCa2c1abb77f'
  const usdc = '0x076488D244A73DA4Fa843f5A8Cd91F655CA81a1e'
  const tenth = '100000000000000000'

  const currentNetwork = networks.operaTestnet.url
  console.log("Deploying to current network: ", currentNetwork)

  const provider = new ethers.providers.JsonRpcProvider(currentNetwork)

  let wallet = new ethers.Wallet(process.env.PRIV_KEY, provider);

  let gasPrice = await provider.getGasPrice()
  console.log("Gas Price: ", gasPrice)

  const params = { gasLimit: String("200028000000"), gasPrice: String(gasPrice.toString()) }

  const newBalance = await wallet.getBalance()

  console.log("Balance of this wallet is: ", newBalance.toString())

  console.log("Deployer address: ", wallet.address)

  console.log("Deploying Bridgerton...")

  const Bridgerton = await ethers.getContractFactory('Bridgerton')
  const bridgerton = await Bridgerton.connect(wallet).deploy(
    stargateRouter,
    { params }
  )
  await bridgerton.deployed()

  console.log("Bridgerton Deployed to: ", bridgerton.address)

  console.log("Deploying Vault")
  const Vault = await ethers.getContractFactory("SavorVault");
  const vault = await Vault.connect(wallet).deploy(
    usdc,  //Underlying USDC 
    bridgerton.address,   // Brigerton
    wallet.address   //Keeper,

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

  // //Set harvest deplay and Harvest Window


  // //Initialize the Vault
  await vault.connect(wallet).initialize()
  console.log("Vault initiliazed")

  console.log("Vault Ready to Go")

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
