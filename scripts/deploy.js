const { ethers } = require("hardhat");
const hre = require("hardhat");
const { BigNumber } = require("ethers");

async function main() {

  await hre.network.provider.request({
    method: "hardhat_impersonateAccount",
    params: [""],
  });

  const signer = await ethers.provider.getSigner("");

  const Vault = await ethers.getContractFactory("GimbalVault");
  
  //Deploy the vault
  let vault = await Vault.deploy(
        vault,
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
