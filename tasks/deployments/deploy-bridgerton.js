const { getObject } = require('../../helpers/utils.js')
const { chainConfigs } = require('../../helpers/constants')
const { deployments } = require('../../helpers/deployments.js')

task('deploy-bridgerton', 'Deploy Bridgerton Contract')
  .addFlag('verify', 'Verify Contracts on Etherscan')
  .setAction( async () => {
    try{
    
      const currentNetwork = hre.network
      const name = currentNetwork.name
      
      console.log(`Deploying Bridgerton contract to ${name} network`)

      let chainConfig = getObject(chainConfigs, name)

      let router = chainConfig.stargateRouter
      
      console.log("Using Strargate router", router)

      const Bridgerton = await ethers.getContractFactory('Bridgerton')

      console.log('Deploying.........')
      const bridgerton = await Bridgerton.deploy(
        router
      )
      await bridgerton.deployed()

      console.log("Bridgerton Deployed to: ", bridgerton.address)

      //Update the address in the Deployments file
      // Does not work yet
      let chainDeploys = getObject(deployments, name);
      console.log("ChainDeploys ", chainDeploys)
      chainDeploys.bridgerton.push(bridgerton.address)

      console.log(`Updated the ${name} Bridgeton address in deployments.js to ${chainDeploys.bridgerton}`)

      //Add logic to verify contract once deployed
      /*
      console.log("Verifing Contract...")
      params = {
        address: bridgerton.address,
        constructorArguments: router
      }
      await hre.run('verify', bridgerton.address, router)
      console.log("Bridgerton Contract verified!")
      */

    } catch(error) {
      console.log(error)
    }
    
  });

