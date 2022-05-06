import { solidity } from "ethereum-waffle";
import { use, expect } from "chai";
import { ethers } from "hardhat";
import { SignerWithAddress } from "@nomiclabs/hardhat-ethers/signers";

use(solidity);

let accounts: SignerWithAddress[]; // SignerWithAddress[]
let bridgerton: any; // Bridgerton contract
let vault: any; // List of vaults
let vaultSecond: any;
let underlying: any; // Underlying ERC20 token for the vaults

const USDC_ON_POLYGON = "0x2791bca1f2de4661ed88a30c99a7a9449aa84174";
const USDT_ON_POLYGON = "0xc2132d05d31c914a87c6611c10748aeb04b58e8f";
const USDC_ON_AVALANCHE = "0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E";
const STARGATEROUTER = "0x45A01E4e04F14f7A4a6702c74187c5F6222033cd"; // Address of the router on Polygon
const ETHER = "1000000000000000000";

describe("Bridgerton contract", function () {
  beforeEach(async function () {
    accounts = await ethers.getSigners();

    /** Deploy core contracts **/

    // Deploy Bridgerton contract
    const Bridgerton = await ethers.getContractFactory("Bridgerton");
    bridgerton = await Bridgerton.deploy(STARGATEROUTER);
    await bridgerton.deployed();

    // Deploy ERC20 token for the vaults
    const Token = await ethers.getContractFactory("GT");
    underlying = await Token.deploy(10000000000000);
    await underlying.deployed();

    // Vault creation, a vault is an ERC4626 contract in our case a Savor4626 contract
    const Vault = await ethers.getContractFactory("SavorVault");
    vault = await Vault.deploy(
      underlying.address,
      bridgerton.address,
      accounts[0].address //TODO: check the test of keepers and their creation, for now accounts[0].address is enough
    );
    await vault.deployed();

    // Creation of the second vault
    const VaultSecond = await ethers.getContractFactory("SavorVault");
    vaultSecond = await VaultSecond.deploy(
      underlying.address,
      bridgerton.address,
      accounts[0].address //TODO: check the test of keepers and their creation, for now accounts[0].address is enough
    );
    await vaultSecond.deployed();

    // Checks
    expect(bridgerton.address).to.not.equal(ethers.constants.AddressZero);
    expect(underlying.address).to.not.equal(ethers.constants.AddressZero);
    expect(vault.address).to.not.equal(ethers.constants.AddressZero);
    expect(vaultSecond.address).to.not.equal(ethers.constants.AddressZero);
  });

  describe("Main functions - Integration tests", function () {
    it("Test setVault", async () => {
      await bridgerton.setVault(vault.address);

      // Checks
      expect(await bridgerton.vaults(vault.address)).to.equal(true);
    });
    it("Add an assets to the Bridgerton", async () => {
      await bridgerton.addAsset(USDC_ON_POLYGON, 1);
      await bridgerton.addAsset(USDT_ON_POLYGON, 2); // check https://stargateprotocol.gitbook.io/stargate/developers/pool-ids for pids
      await bridgerton.addAsset(USDC_ON_AVALANCHE, 1);

      // Checks
      expect(await bridgerton.pids(USDC_ON_POLYGON)).to.equal(1);
      expect(await bridgerton.pids(USDT_ON_POLYGON)).to.equal(2);
      expect(await bridgerton.pids(USDC_ON_AVALANCHE)).to.equal(1);
    });

    it("Test sweep function", async () => {
      const initialTokenBalanceSender = await underlying.balanceOf(
        accounts[0].address
      );
      const initialTokenBalanceBridgerton = await underlying.balanceOf(
        bridgerton.address
      );

      // Transfer tokens to the bridgerton contract
      await underlying.transfer(bridgerton.address, 100);
      expect(await underlying.balanceOf(bridgerton.address)).to.equal(100);

      await bridgerton.sweep(underlying.address);

      // Checks
      expect(await underlying.balanceOf(accounts[0].address)).to.equal(
        initialTokenBalanceSender
      );
      expect(await underlying.balanceOf(bridgerton.address)).to.equal(
        initialTokenBalanceBridgerton
      );
    });
  });
});
