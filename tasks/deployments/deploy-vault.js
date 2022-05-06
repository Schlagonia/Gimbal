const { getObject } = require('../../helpers/utils.js')
const { chainConfigs } = require('../../helpers/constants')
const { deployments } = require('../../helpers/deployments.js')

task('deploy-vault', 'Deploy Savor Vault Contract')
.addParam('coin', 'Coin to set as Vaults Underlying')
  .addFlag('verify', 'Verify Contracts on Etherscan')
  .setAction( async () => {
    try{
    
      const currentNetwork = hre.network
      const name = currentNetwork.name
      
      console.log(`Deploying Savor Vault contract to ${name} network`)

      let chainConfig = getObject(chainConfigs, name)
      let chainDeploys = getObject(deployments, name);
      
      let underlying = chainConfig.coin
      let bridgerton = chainDeploys.bridgerton[-1]
      
      console.log(`Using ${coin} as underlying for vault`)

      const Vault = await ethers.getContractFactory('SavorVault')

      console.log('Deploying Vault.........')
      const vault = await Vault.deploy(
        underlying,
        bridgerton
      )
      await vault.deployed()

      console.log("Vault Deployed to: ", vault.address)

      //Update the address in the Deployments file
      // Does not work yet
      
      chainDeploys.vault.push(vault.address)

      console.log(`Updated the ${name} Vault address in deployments.js to ${chainDeploys.vault}`)

      //Add logic to verify contract once deployed
      /*
      console.log("Verifing Contract...")
      params = {
        address: vault.address,
        constructorArguments: router
      }
      await hre.run('verify', vault.address, )
      console.log("Vault Contract verified!")
      */

    } catch(error) {
      console.log(error)
    }
    
  });

