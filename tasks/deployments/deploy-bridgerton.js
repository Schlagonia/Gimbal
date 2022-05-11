const { 
  getObject, 
  updateAddress, 
  sleep 
} = require('../../helpers/utils.js')
const { chainConfigs } = require('../../helpers/constants')

task('deploy-bridgerton', 'Deploy Bridgerton Contract')
  .addFlag('verify', 'Verify Contracts on Etherscan')
  .setAction( async ({ verify }) => {
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
      console.log("Updating Bridgerton Address")
      updateAddress(chain, 'bridgerton', bridgerton.address)
      console.log("Address updated in Deployments.json File")
      
      if(verify) {
        console.log("Sleeping for 1 minute for Etherscan to recognize deployment")
        await sleep(75000)
        console.log("Verifing Contract...")
        params = {
          address: bridgerton.address,
          constructorArguments: [router]
        }
        await hre.run('verify:verify', params)
        console.log("Bridgerton Contract verified!")
      }
      
    } catch(error) {
      console.log(error)
    }
    
  });

