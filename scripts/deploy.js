const { ethers } = require("hardhat");
const hre = require("hardhat");
const { impersonateAddress } = require("../helpers/misc-utils");

async function main() {

  const signer = await impersonateAddress('');

  const Vault = await ethers.getContractFactory("GimbalVault");
  
  //Deploy the vault
  let vault = await Vault.connect(signer).deploy(
        '', //Underlying,
        '', //Keeper,
        '' // Stargate Router,
        )
    await vault.deployed()
    console.log("Vult Deployed: ", vault.address)

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
