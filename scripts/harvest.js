const { ethers } = require("hardhat");
const hre = require("hardhat");
const { networks } = require('../hardhat.config')
const SavorVault = require('../abis/SavorVault.json')
const Bridgerton = require('../abis/Bridgerton.json')
const { impersonateAddress } = require("../helpers/misc-utils");

//must create a .env file with the variable PRIVATE_KEY. Usage: process.env.PRIVATE_KEY
require('dotenv').config()

async function main() {

  const vaultAddress = '0x886b2A3dc127C1122c005669F726d5D37A135411'
  const bridgertonAddress = '0x51Fc722819579f0ed58dcAC14c203aee70b78B74'

  const rinkebyId = '10001'
  const mumbaiId = '10009'

  const stargateRouter = '0x82A0F5F531F9ce0df1DF5619f74a0d3fA31FF561'
  const usdc = '0x1717A0D5C8705EE89A8aD6E808268D6A826C97A4'
  const tenth = '100000000000000000'

  const rinkeby = networks.rinkeby.url
  const mumbai = networks.mumbai.url

  const rinkebyProvider = new ethers.providers.JsonRpcProvider(rinkeby)
  const mumbaiProvider = new ethers.providers.JsonRpcProvider(mumbai)

  let rinkebyWallet = new ethers.Wallet(process.env.PRIV_KEY, rinkebyProvider);
  let mumbaiWallet = new ethers.Wallet(process.env.PRIV_KEY, mumbaiProvider)

  console.log("Instantiating Contracts...")
  let rinkebyVault = new ethers.Contract(
      vaultAddress,
      SavorVault.abi,
      rinkebyWallet
  )

  let mumbaiVault = new ethers.Contract(
      vaultAddress,
      SavorVault.abi,
      mumbaiWallet
  )

  let bridgertonRinkeby = new ethers.Contract(
      bridgertonAddress,
      Bridgerton.abi,
      rinkebyWallet
  )
  console.log("Contracts Created...")
  let rinkebyBalance = await rinkebyVault.thisVaultsHoldings()
  console.log("Current Rinkeby Holdings ", rinkebyBalance.toNumber())

  console.log('Running harvest on Rinkeby...')
    //Call harvest on Vault moving funds from
  let tx = await rinkebyVault.connect(rinkebyWallet).runHarvest(
    '0',
    '0',
    '1000000000000000000'
  )
  await tx.wait()

  rinkebyBalance = await rinkebyVault.thisVaultsHoldings()
  console.log("Current Rinkeby Holdings ", rinkebyBalance.toNumber())

  let amount = rinkebyBalance.toNumber() * .9
  console.log("Amount ", amount)

  let swapFee = await bridgertonRinkeby.externalGetSwapFee(
      mumbaiId,
      vaultAddress,
      vaultAddress
  )

  console.log("Swap Fee ", swapFee)

  console.log("Sending swap call ...")
  //Call Swap on vault moving funds from
  tx = await rinkebyVault.connect(rinkebyWallet).swap(
      mumbaiId,
      amount,
      vaultAddress,
      { value: swapFee }
  )

  await tx.wait()
  console.log("Swapped Called Succeffully!!! ")

  //Call harvest on vault funds were moved to
  mumbaiBalance = await mumbaiVault.thisVaultsHoldings()
  console.log("Mumbai Balance ", mumbaiBalance.toNumber())
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
