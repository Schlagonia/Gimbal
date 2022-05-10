const { getObject, updateAddress } = require('../../helpers/utils.js')
const deployments = require('../../deployments.json')

task('deploy-strategy', 'Deploy a new Strategy Contract and add it to the Vaults stack')
  .addParam('coin', 'Coin to set as Vaults Underlying')
  .addFlag('verify', 'Verify Contracts on Etherscan')
  .setAction( async ({ coin }) => {
    try{
    
      const currentNetwork = hre.network
      const chain = currentNetwork.name
      
      console.log(`Deploying new Strategy to ${chain} network`)

      let vault = deployments[chain].vault
      console.log("Adding to the Vault at ", vault)

      //Needs to be updated to the Contract being deployed
      const Strategy = await ethers.getContractFactory('AaveLender')
        console.log("Using ", account)
      console.log('Deploying.........')
 
      //custom parameters need to be added manually here
      const strategy = await Strategy.deploy(
        vault
      )
      await strategy.deployed()

      console.log("Strategy Deployed to: ", strategy.address)

      //Push the Strategy to the front of the withdrawal stack
      vault.pushToWithdrawalStack(strategy)

      // Allow the vault to deposit into the strategy
      vault.trustStrategy(strategy)

      //Update the address in the Deployments file
      console.log("Updating Bridgerton Address")
      updateAddress(chain, 'bridgerton', '0x6290fd4B32Dd0056eFB3D8E6319599A34cCCc387')
      console.log("Address updated in Deployments.json File")
    
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

