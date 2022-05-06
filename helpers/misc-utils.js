const { ethers } = require("hardhat");
const hre = require("hardhat");
const { networks } = require('../hardhat.config')
const { BigNumber } = require("ethers");
const { Wallet, ContractTransaction, Signer } = require('ethers');


function stringToBigNumber(amount) {
  return new BigNumber(amount);
}

const getWallet = (network) => {
  const provider = new ethers.providers.JsonRpcProvider(networks.network.url)
  return new ethers.Wallet(process.env.PRIV_KEY, provider)
}

const sleep = (milliseconds) => {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
};

const createRandomAddress = () => Wallet.createRandom().address;

const evmSnapshot = async () => await hre.ethers.provider.send('evm_snapshot', []);

const evmRevert = async (id) => hre.ethers.provider.send('evm_revert', [id]);

const timeLatest = async () => {
  const block = await hre.ethers.provider.getBlock('latest');
  return new BigNumber(block.timestamp);
};

const advanceBlock = async (timestamp) =>
  await hre.ethers.provider.send('evm_mine', [timestamp]);

const increaseTime = async (secondsToIncrease) => {
  await hre.ethers.provider.send('evm_increaseTime', [secondsToIncrease]);
  await hre.ethers.provider.send('evm_mine', []);
};

// Workaround for time travel tests bug: https://github.com/Tonyhaenn/hh-time-travel/blob/0161d993065a0b7585ec5a043af2eb4b654498b8/test/test.js#L12
const advanceTimeAndBlock = async function (forwardTime) {
  const currentBlockNumber = await hre.ethers.provider.getBlockNumber();
  const currentBlock = await hre.ethers.provider.getBlock(currentBlockNumber);

  if (currentBlock === null) {
    /* Workaround for https://github.com/nomiclabs/hardhat/issues/1183
     */
    await hre.ethers.provider.send('evm_increaseTime', [forwardTime]);
    await hre.ethers.provider.send('evm_mine', []);
    //Set the next blocktime back to 15 seconds
    await hre.ethers.provider.send('evm_increaseTime', [15]);
    return;
  }
  const currentTime = currentBlock.timestamp;
  const futureTime = currentTime + forwardTime;
  await hre.ethers.provider.send('evm_setNextBlockTimestamp', [futureTime]);
  await hre.ethers.provider.send('evm_mine', []);
};

const waitForTx = async (tx) => await tx.wait(1);

const filterMapBy = (raw, fn) =>
  Object.keys(raw)
    .filter(fn)
    .reduce((obj, key) => {
      obj[key] = raw[key];
      return obj;
    }, {});

const chunk = (arr, chunkSize) => {
  return arr.reduce(
    (prevVal, currVal, currIndx, array) =>
      !(currIndx % chunkSize)
        ? prevVal.concat([array.slice(currIndx, currIndx + chunkSize)])
        : prevVal,
    []
  );
};

const impersonateAddress = async (address) => {
  
    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [address],
    });
  
  const signer = hre.ethers.provider.getSigner(address);

  return {
    signer
  };
};

const omit = (obj, keys) =>
  (Object.keys(obj) ).reduce(
    (acc, curr) => (keys.includes(curr) ? acc : { ...acc, [curr]: obj[curr] }),
    {}
  );

const impersonateAccountsHardhat = async (accounts) => {

  // eslint-disable-next-line no-restricted-syntax
  for (const account of accounts) {
    // eslint-disable-next-line no-await-in-loop
    await hre.network.provider.request({
      method: 'hardhat_impersonateAccount',
      params: [account],
    });
  }
};


module.exports = { impersonateAccountsHardhat, omit, impersonateAddress, chunk, filterMapBy, waitForTx, advanceTimeAndBlock, increaseTime , advanceBlock, timeLatest, evmRevert, evmSnapshot, createRandomAddress, sleep, getWallet, stringToBigNumber }