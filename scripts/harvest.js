const { ethers } = require("hardhat");
const hre = require("hardhat");
const { networks } = require('../hardhat.config')
const SavorVault = require('../abis/SavorVault.json')
const Bridgerton = require('../abis/Bridgerton.json')
const { 
  getObject, 
  updateAddress, 
  sleep,
  getSigner,
} = require('../helpers/utils.js')
const { chainConfigs } = require('../helpers/constants');
const { BigNumber } = require("ethers");

//must create a .env file with the variable PRIVATE_KEY. Usage: process.env.PRIVATE_KEY
require('dotenv').config()

async function main() {

  let harvest = true;
  let swap = false;

  const currentNetwork = hre.network
  let chain = currentNetwork.name
  //chain = 'polygon'
  let wallet = await getSigner(hre);

  const vaultAddress = '0x886b2A3dc127C1122c005669F726d5D37A135411'
  const bridgertonAddress = '0x51Fc722819579f0ed58dcAC14c203aee70b78B74'
  const wad = BigNumber.from('1000000000000000000')

  //Get the opposite of the chain we are on for the swap function
  let chainConfig = chain == 'avalanche' ? getObject(chainConfigs, 'polygon') : getObject(chainConfigs, 'avalanche')

  let secondUrl = chain == 'avalanche' ? networks.polygon.url : networks.avalanche.url
  const secondProvider = new ethers.providers.JsonRpcProvider(secondUrl)
  
  let secondWallet = new ethers.Wallet(process.env.PRIV_KEY, secondProvider)
 
  console.log("Instantiating Contracts...")
  let activeVault = new ethers.Contract(
      vaultAddress,
      SavorVault.abi,
      wallet
  )

  let secondVault = new ethers.Contract(
      vaultAddress,
      SavorVault.abi,
      secondWallet
  )

  let bridgerton = new ethers.Contract(
      bridgertonAddress,
      Bridgerton.abi,
      wallet
  )
  console.log("Contracts Created...")
  let activeBalance = await activeVault.thisVaultsHoldings()
  console.log("Active Balance ", activeBalance.toString())
  let secondBalance = await secondVault.thisVaultsHoldings()
  console.log("Second balance ", secondBalance.toString())
  
  let totalHoldings = activeBalance.add(secondBalance)
  console.log("Current total Holdings ", totalHoldings.toString())

  let tx;

  if(harvest) {

    console.log('Running harvest on Active chain...')

    let newFloat = '20000000000000000'

    let currentCash = await activeVault.totalFloat()
    console.log("Current Cash ", currentCash)
    let targetFloat = activeBalance.mul(BigNumber.from(newFloat)).div(wad)
    console.log("Target Float ", targetFloat)

    let toDeposit = currentCash.sub(targetFloat)
    
    console.log("To Deposit ", toDeposit)
    //Call harvest on Vault moving funds from
    tx = await activeVault.connect(wallet).runHarvest(
      '0', // To withdraw
      toDeposit, // ToDeposit
      newFloat, //New float
      true // funds deployed on this chain
    )
    await tx.wait()

    activeBalance = await activeVault.thisVaultsHoldings()
    console.log("Current Active Holdings ", activeBalance.toString())
  }

  if(swap) {

    let chainId = chainConfig.stargateChainId
    console.log("Chain ID ", chainId)

    let amount = activeBalance.mul(9).div(10)
    console.log("Amount ", amount)

    let swapFee = await bridgerton.externalGetSwapFee(
        chainId,
        vaultAddress,
        vaultAddress
    )

    console.log("Swap Fee ", swapFee)

    console.log("Sending swap call ...")
    //Call Swap on vault moving funds from
    tx = await activeVault.connect(wallet).swap(
        chainId,
        String(amount),
        vaultAddress,
        { value: swapFee }
    )

    await tx.wait()
    console.log("Swapped Called Succeffully!!! ")
  }
  
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
