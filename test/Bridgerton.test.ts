const solidity = require("ethereum-waffle").solidity;
const expect = require("chai").expect;
const use = require("chai").use;
const ethers = require("hardhat").ethers;
const SignerWithAddress =
  require("@nomiclabs/hardhat-ethers/signers").SignerWithAddress;
// const ERC20 = require("../contracts/Solmate/tokens/ERC20.sol");

use(solidity);

let accounts; // SignerWithAddress[]
const stargateRouter = "0x45A01E4e04F14f7A4a6702c74187c5F6222033cd"; // Address of the router on Polygon check the hlepers to get it on mumbay and other networks
let bridgerton; // Bridgerton contract
let vault; // List of vaults
let underlying; // Underlying ERC20 token for the vault

describe("Bridgerton contract", function () {
  beforeEach(async function () {
    accounts = await ethers.getSigners();

    /** Deploy core contracts **/

    // Deploy Bridgerton
    const Bridgerton = await ethers.getContractFactory("Bridgerton");
    bridgerton = await Bridgerton.deploy(stargateRouter);
    await bridgerton.deployed();

    console.log("Bridgerton Deployed to: ", bridgerton.address);

    // ===================
    // Creation of the ERC20 token for the vault
    const Token = await ethers.getContractFactory("ERC20");
    const underlying = await Token.deploy();
    await underlying.deployed();

    // underlying = new ERC20("Test Token", "TTK"); 
    // underlying = "0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174" // has to be a ERC20 
    
    // ===================
    // Creation of keepers to test setVault function
    //TODO: check the test of keepers and theri cretaion

    // ===================
    // Creation of vaults to test setVault function
    // first they shouldn't be allowed to do call the swap fuunction
    // but after beeing allowed it should work

    // Creation of the first vault, what is a vault=> a vault is an ERC4626 contract in our case a Savor4626 contract
    const Vault = await ethers.getContractFactory("SavorVault");
    vault = await Vault.deploy(underlying, bridgerton, accounts[0].address); //  ERC20 _UNDERLYING, address _bridgerton, address _keeper by default is msg.sender
    await vault.deployed();

    // console.log("Vault Deployed to: ", vault.address);

    //Checks
    expect(bridgerton.address).to.not.equal(ethers.constants.AddressZero);
  });
  describe("Transactions", function () {
    it("Test setVault", async () => {
      console.log("TEST");
    });
  });
});

