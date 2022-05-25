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

  const avax = networks.avalanche.url
  const poly = networks.polygon.url

  const avaxProvider = new ethers.providers.JsonRpcProvider(avax)
  const polyProvider = new ethers.providers.JsonRpcProvider(poly)

  let avaxWallet = new ethers.Wallet(process.env.PRIV_KEY, avaxProvider);
  let polyWallet = new ethers.Wallet(process.env.PRIV_KEY, polyProvider)

  console.log("Instantiating Contracts...")
  let avaxVault = new ethers.Contract(
      vaultAddress,
      SavorVault.abi,
      avaxWallet
  )

  let polyVault = new ethers.Contract(
      vaultAddress,
      SavorVault.abi,
      polyWallet
  )

  console.log("Contracts Created...")
  let avaxBalance = await avaxVault.thisVaultsHoldings()
  console.log("avax Balance ", avaxBalance.toString())
  let polyBalance = await polyVault.thisVaultsHoldings()
  console.log("poly balance ", polyBalance.toString())
  
  let totalHoldings = avaxBalance.add(polyBalance)
  console.log("Current total Holdings ", totalHoldings.toString())

  let avaxSupply = await avaxVault.thisVaultsSupply()
  console.log("avax supply ", avaxSupply.toString())
  let polySupply = await polyVault.thisVaultsSupply()
  console.log("poly supply ", polySupply.toString())
  
  let totalSupply = avaxSupply.add(polySupply)
  console.log("Total Supply is ", totalSupply.toString())

  let newVirtualPrice = totalHoldings.mul(wad).div(totalSupply)
  console.log('New virtual price will be ', newVirtualPrice.toString())

  console.log('Updating the VP on avax and poly...')
    //Call harvest on Vault moving funds from
  let tx = await avaxVault.connect(avaxWallet).updateVirtualPrice(
    newVirtualPrice
  )

  let tx2 = await polyVault.connect(polyWallet).updateVirtualPrice(
    newVirtualPrice
    )

  await tx.wait()
  console.log("Avax vp updated")  
  await tx2.wait()
  console.log("Poly vp updated")

  console.log("Virtual Prices updated on both chains")

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
