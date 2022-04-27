const { ethers } = require("hardhat");
const hre = require("hardhat");
const { impersonateAddress } = require("../helpers/misc-utils");

//must create a .env file with the variable PRIVATE_KEY. Usage: process.env.PRIVATE_KEY
require('dotenv').config()


async function main() {

  const signer = await impersonateAddress(process.env.PRIVATE_KEY);
  const Vault = await ethers.getContractFactory("GimbalVault");



  //Deploy the vault
  let vault = await Vault.connect(signer).deploy(
    '', //Underlying,
    '', //Keeper,
    '' // Stargate Router,
  )
  await vault.deployed()
  console.log("Vault Deployed: ", vault.address)

  //set the fee percent

  //Set Target Float

  //Set harvest deplay and Harvest Window

  //Initialize the Vault

  console.log("Vault Ready to Go")
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
