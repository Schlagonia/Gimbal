const { 
  getObject, 
  updateAddress,
  getSigner,
  sleep
 } = require('../../helpers/utils.js')
const { 
  chainConfigs, 
  targetFloat, 
  targetFee,
  harvestDelay,
  harvestWindow
 } = require('../../helpers/constants')
const deployments = require('../../deployments.json')
const  Bridgerton  = require('../../abis/Bridgerton.json');


task('deploy-vault', 'Deploy Savor Vault Contract'
)
  .addParam('coin', 'Coin to set as Vaults Underlying')
  .addFlag('verify', 'Verify Contracts on Etherscan')
  .setAction( async ({ coin,  verify }) => {
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
      // Sets performance fee to 5%
      console.log("Setting performance fee...")
      let tx = await vault.setFeePercent(targetFee)
      await tx.wait()
      console.log("Perforance fee set")

        // //Set Target Float to 100% till harvest
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

      //Then can set a harvest window if desired otherwise it will be set to 0
      console.log("Setting the Harvest window...")
      tx = await vault.setHarvestWindow(harvestWindow)
      await tx.wait()
      console.log("Harvest Window Set")

      // //Initialize the Vault
      console.log("Initiliazing Vault...")
      tx = await vault.initialize()
      await tx.wait()
      console.log("Vault initiliazed")

      //Update the address in the Deployments file
      updateAddress(chain, 'vault', vault.address)

      console.log(`Updated the ${chain} Vault address in deployments.json`)


      let signer = await getSigner(hre)

      const Bridger = await new ethers.Contract(
          bridgerton,
          Bridgerton.abi,
          signer
      )

      const owner = await Bridger.owner();
      if(owner == signer.address) {
        console.log("Adding the Vault to Bridgerton Contract...")
        tx = await Bridger.setVault(vault.address)
        await tx.wait()
        console.log("Vault added")

        console.log(`Adding ${coin} PID in Bridgerton....`)
        let pid = chainConfig[`${coin}Pid`]
        tx = await Bridger.addAsset(underlying, pid)
        await tx.wait()
        console.log(`${coin} added into Bridgerton Contract`)

        console.log("Transferring ownership of Bridgerton...")
        tx = await Bridger.transferOwnerShip('Add Address')
        await tx.wait()
        console.log("Bridgerton ownership transferred")
      } 

      console.log("Vault Ready to Go!!")

      if(verify) {
        console.log("Sleeping for 1 minute for Etherscan to recognize deployment")
        await sleep(75000)
        console.log("Verifing Contract...")
        params = {
          address: vault.address,
          constructorArguments: [underlying, bridgerton]
        }
        await hre.run('verify:verify', params)
        console.log("Vault Contract verified!")
      }

      console.log("Transferring ownership of Vault...")
      tx = await vault.transferOwnerShip('Add Address')
      await tx.wait()
      console.log("Vault ownership transferred and set up complete!")

    } catch(error) {
      console.log(error)
    }
    
  });

