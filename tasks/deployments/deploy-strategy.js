const {  getSigner, sleep } = require('../../helpers/utils.js')
const deployments = require('../../deployments.json');
const  SavorVault  = require('../../abis/SavorVault.json')


task('deploy-strategy', 'Deploy a new Strategy Contract and add it to the Vaults stack')
  .addFlag('verify', 'Verify Contracts on Etherscan')
  .setAction( async ({ verify }) => {
    try{
    
      const currentNetwork = hre.network
      const chain = currentNetwork.name
      
      console.log(`Deploying new Strategy to ${chain} network`)

      let vault = deployments[chain].vault
      console.log("Adding to the Vault at ", vault)

      //Needs to be updated to the Contract being deployed
      const Strategy = await ethers.getContractFactory('Vectorfied')
    
      console.log('Deploying.........')
 
      //custom parameters need to be added manually here ///
      const strategy = await Strategy.deploy(
        vault, 
        '0x1338b4065e25AD681c511644Aa319181FC3d64CC', // Vecotr Pool
        '0x60aE616a2155Ee3d9A68541Ba4544862310933d4' // Uni V2 Router
      )
      await strategy.deployed()

      console.log("Strategy Deployed to: ", strategy.address)

      let signer = await getSigner(hre)

      const Vault = new ethers.Contract(
          vault,
          SavorVault.abi,
          signer
      )

      const owner = await Vault.owner();

      //Can only add the strategy to the Vault if you are the owner
      if(owner == signer.address) {
        //Push the Strategy to the front of the withdrawal stack
        console.log("Adding the Strategy to the Vaults withdrawal stack....")
        let tx = await Vault.pushToWithdrawalStack(strategy.address)
        await tx.wait()
        console.log("Strategy added")

        // Allow the vault to deposit into the strategy
        console.log("Adding Strategy as trusted in the Vault....")
        tx = await Vault.trustStrategy(strategy.address)
        await tx.wait()
        console.log("Strategy Trusted.")
      }
      
      if(verify) {
        console.log("Sleeping for 1 minute for Etherscan to recognize deployment")
        await sleep(75000)
        console.log("Verifing Contract...")
        params = {
          address: strategy.address,
          ///THIS NEEDS TO BE UPDATED BASED ON STRAT PARAMS ///
          constructorArguments: [
            vault,
            '0x1338b4065e25AD681c511644Aa319181FC3d64CC', // Vecotr Pool
            '0x60aE616a2155Ee3d9A68541Ba4544862310933d4'
          ]
        }
        await hre.run('verify:verify', params)
        console.log("Strategy Contract verified!")
      }

    } catch(error) {
      console.log(error)
    }
    
  });

