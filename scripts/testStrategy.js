const { ethers } = require("hardhat");
const hre = require("hardhat");
const { networks } = require('../hardhat.config')
const SavorVault = require('../abis/SavorVault.json')
const Bridgerton = require('../abis/Bridgerton.json')
const Strategy = require('../artifacts/contracts/Strategies/Vectorfied.sol/Vectorfied.json')
const ERC20 = require('../abis/erc20.abi.json')
const { impersonateAddress } = require("../helpers/misc-utils");
const { getSigner } = require("../helpers/utils.js")

//must create a .env file with the variable PRIVATE_KEY. Usage: process.env.PRIVATE_KEY
require('dotenv').config()

const vaultAddress = '0x886b2A3dc127C1122c005669F726d5D37A135411'
const usdcAddress = '0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E'


let vault;
let strategy;
let usdc;

const print = async () => {
    let vaultUsdc = await usdc.balanceOf(vaultAddress)
    let vaultHolding = await vault.thisVaultsHoldings()
    console.log(`The Vault has a total balance of ${vaultHolding.toString()}`)
    console.log(`The Vault is holding ${vaultUsdc.toString()} in usdc`)
    let stratAssets = await strategy.estimatedTotalAssets()
    let stratUsdc = await usdc.balanceOf(strategy.address)
    console.log(`The Strategy has a total balance of ${stratAssets.toString()}`)
    console.log(`The Strategy is holding ${stratUsdc.toString()} in usdc`)
    console.log(`The total between both is ${vaultUsdc.add(stratAssets).toString()}`)

}

async function main() {

  let signer = await getSigner(hre)

  console.log("Instantiating Contracts...")
  vault = new ethers.Contract(
      vaultAddress,
      SavorVault.abi,
      signer
  )

  usdc = new ethers.Contract(
      usdcAddress,
      ERC20.abi,
      signer
  )

  console.log("Contracts Created...")

  console.log("Deploying Strategy")
  const Strategy = await ethers.getContractFactory("Vectorfied");
  strategy = await Strategy.deploy(
    vaultAddress,  // 
    '0x1338b4065e25AD681c511644Aa319181FC3d64CC', // Vecotr Pool
    '0x60aE616a2155Ee3d9A68541Ba4544862310933d4' // Uni V2 Router
  )

  await strategy.deployed()
  console.log("Strategy Deployed: ", strategy.address)

  // Add strategy to the vault
  console.log("Adding Strategy to the Vault")
  let tx = await vault.connect(signer).pushToWithdrawalStack(strategy.address);
  await tx.wait()
  console.log("Strat pushed to withdrawal stack")

  // Trust the strategy
  console.log("Trusting Strateguy...")
  tx = await vault.connect(signer).trustStrategy(strategy.address)
  await tx.wait()
  console.log("strat is now trusted by the vault")

  //call the harvest with depositing funds
  await print()
  console.log('Running harvest...')
    //Call harvest on Vault moving funds from
  let bal = await usdc.balanceOf(vaultAddress)
  
  let toDeposit = bal.mul(90).div(100)
  tx = await vault.connect(signer).runHarvest(
    '0',
    toDeposit,
    '100000000000000000',
    true
  )
  await tx.wait()
  console.log(`Harvested with a deposit of  ${toDeposit}`)

  //call the harvest with withdrawing some funds
  await print()

  console.log('Running harvest with a withdraw...')
    //Call harvest on Vault moving funds from
  bal = await strategy.estimatedTotalAssets()
  let toWithdraw = bal.mul(50).div(100)
  tx = await vault.connect(signer).runHarvest(
    toWithdraw,
    '0',
    '100000000000000000',
    true
  )
  await tx.wait()
  console.log(`Harvested with a withdraw of  ${toWithdraw}`)
   
  // Deposit funds as a user
  await print()
  console.log('Running User Deposit...')
    //Call harvest on Vault moving funds from
  bal = await usdc.balanceOf(signer.address)

  tx = await usdc.approve(vaultAddress, bal.mul(10))
  await tx.wait()
  
  toDeposit = '10000000'
  tx = await vault.connect(signer).deposit(
    toDeposit,
    signer.address
  )
  await tx.wait()
  console.log(`Deposited int the vault with a deposit of  ${toDeposit}`)

  //Withdraw funds as a user
  await print()
  console.log('Running a user withdraw...')
    //Call harvest on Vault moving funds from
  bal = await strategy.estimatedTotalAssets()
  toWithdraw = bal.mul(50).div(100)
  tx = await vault.connect(signer).withdraw(
    toWithdraw,
    signer.address,
    signer.address
  )
  await tx.wait()
  console.log(`Withdawn funds with a withdraw of  ${toWithdraw}`)

  // Call the harvest and withdraw all funds
  await print()
  console.log('Running harvest with a withdraw...')
    //Call harvest on Vault moving funds from
  bal = await vault.thisVaultsHoldings()
  toWithdraw = bal
  tx = await vault.connect(signer).runHarvest(
    toWithdraw,
    '0',
    '100000000000000000',
    true
  )
  await tx.wait()
  console.log(`Harvested with a withdraw of  ${toWithdraw}`)

  await print()


}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
