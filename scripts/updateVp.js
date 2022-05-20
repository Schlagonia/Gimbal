const { ethers } = require("hardhat");
const hre = require("hardhat");
const { networks } = require('../hardhat.config')
const SavorVault = require('../abis/SavorVault.json')
const { BigNumber } = require("ethers");

//must create a .env file with the variable PRIVATE_KEY. Usage: process.env.PRIVATE_KEY
require('dotenv').config()

async function main() {

  const wad = BigNumber.from('1000000000000000000')
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

  console.log("Contracts Created...")
  let rinkebyBalance = await rinkebyVault.thisVaultsHoldings()
  console.log("Rinkeby Balance ", rinkebyBalance.toString())
  let mumbaiBalance = await mumbaiVault.thisVaultsHoldings()
  console.log("Mumbai balance ", mumbaiBalance.toString())
  
  let totalHoldings = rinkebyBalance.add(mumbaiBalance)
  console.log("Current total Holdings ", totalHoldings.toString())

  let rinkebySupply = await rinkebyVault.thisVaultsSupply()
  console.log("Rinkeby supply ", rinkebySupply.toString())
  let mumbaiSupply = await mumbaiVault.thisVaultsSupply()
  console.log("Mumbai supply ", mumbaiSupply.toString())
  
  let totalSupply = rinkebySupply.add(mumbaiSupply)
  console.log("Total Supply is ", totalSupply.toString())

  let newVirtualPrice = totalHoldings.mul(wad).div(totalSupply)
  console.log('New virtual price will be ', newVirtualPrice.toString())

  
  console.log('Updating the VP on Rinkeby and mumbai...')
    //Call harvest on Vault moving funds from
  let tx = await rinkebyVault.connect(rinkebyWallet).updateVirtualPrice(
    newVirtualPrice
  )

  let tx2 = await mumbaiVault.connect(mumbaiWallet).updateVirtualPrice(
    newVirtualPrice
    )
  await tx2.wait()

  console.log("Virtual Prices updated on both chains")

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
