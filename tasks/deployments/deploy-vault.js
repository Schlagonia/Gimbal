const { getObject, updateAddress } = require('../../helpers/utils.js')
const { 
  chainConfigs, 
  targetFloat, 
  targetFee,
  harvestDelay
 } = require('../../helpers/constants')
const deployments = require('../../deployments.json')

task('deploy-vault', 'Deploy Savor Vault Contract'
)
  .addParam('coin', 'Coin to set as Vaults Underlying')
  .addFlag('verify', 'Verify Contracts on Etherscan')
  .setAction( async ({ coin }) => {
    try{
    
      const currentNetwork = hre.network
      const chain = currentNetwork.name
      
      console.log(`Deploying Savor Vault contract to ${chain} network`)

      let chainConfig = getObject(chainConfigs, chain)
      
      let underlying = chainConfig[coin]
      let bridgerton = deployments[chain]['bridgerton']

      console.log(`Using ${coin} as underlying for vault at ${underlying}`)
      console.log('Bridgerton ', bridgerton)
      const Vault = await ethers.getContractFactory('SavorVault')

      console.log('Deploying Vault.........')
      const vault = await Vault.deploy(
        underlying,
        bridgerton
      )
      await vault.deployed()

      console.log("Vault Deployed to: ", vault.address)

       // //set the fee percent
      // Sets performance fee to 10%
      console.log("Setting performance fee...")
      let tx = await vault.setFeePercent(targetFee)
      await tx.wait()
      console.log("Perforance fee set")

        // //Set Target Float
      console.log("Setting the Target Float Amount...")
      tx = await vault.setTargetFloat(targetFloat)
      await tx.wait()
      console.log("Targe Float Set")

      // //Set harvest deplay and Harvest Window
      //Need to set Harvest Delay first for locked profit
      console.log("Setting harvest delay...")
      tx = await vault.setHarvestDelay(harvestDelay)
      await tx.wait()
      console.log("Harvest delay set")
      //Then can set a harvest window if desired
 

      // //Initialize the Vault
      console.log("Initiliazing Vault...")
      tx = await vault.initialize()
      await tx.wait()
      console.log("Vault initiliazed")

      console.log("Vault Ready to Go")

      //Update the address in the Deployments file
      updateAddress(chain, 'vault', vault.address)

      console.log(`Updated the ${chain} Vault address in deployments.json`)

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

