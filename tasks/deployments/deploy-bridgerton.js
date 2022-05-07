const { getObject } = require('../../helpers/utils.js')
const { chainConfigs } = require('../../helpers/constants')
const { deployments, setDeployment } = require('../../helpers/deployments.js')

task('deploy-bridgerton', 'Deploy Bridgerton Contract')
  .addFlag('verify', 'Verify Contracts on Etherscan')
  .setAction( async () => {
    try{
    
      const currentNetwork = hre.network
      const chain = currentNetwork.name
      
      console.log(`Deploying Bridgerton contract to ${chain} network`)

      let chainConfig = getObject(chainConfigs, chain)

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
      setDeployment(chain, 'bridgerton', bridgerton.address)

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

