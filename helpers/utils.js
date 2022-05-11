const fs = require('fs');
const path = './deployments.json'

const getSigner = async (hre) => {
    const signers = await hre.ethers.getSigners()
    return signers[0]
}

//returns an object in the list with chainId parameter
const getObject = (list, chainId) => {
  
    for (let i = 0; i < list.length; i++) {
        let chain = list[i].chain
        
        if (chain == chainId) {
            return list[i]
        }
    }
  }

const getIndex = (list, chainId) => {
    for (let i = 0; i < list.length; i++) {
        let chain = list[i].chain
        
        if (chain == chainId) {
            return i;
        }
    }
}

const updateAddress = (chain, contract, address) => {
    let deployments = require('../deployments.json')

    deployments[chain][contract] = address
    
    data = JSON.stringify(deployments, null, 2)
    
    fs.writeFileSync(path, data)
}

const sleep = (milliseconds) => {
    return new Promise((resolve) => setTimeout(resolve, milliseconds));
  };


module.exports = {
    getObject,
    getIndex,
    updateAddress,
    getSigner,
    sleep
}