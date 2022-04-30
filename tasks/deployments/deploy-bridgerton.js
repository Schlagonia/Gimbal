//const { addresses } = require('../../helpers/constants')
//const { getWallet } = require('../../helpers/misc-utils')

const addresses = {
  rinkeby: '0x82A0F5F531F9ce0df1DF5619f74a0d3fA31FF561',
  mumbai :  '0x817436a076060D158204d955E5403b6Ed0A5fac0',
}

task('deploy-bridgerton', 'Deploy Bridgerton Contract')
  .addFlag('verify', 'Verify Contracts on Etherscan')
  .setAction( async ( { chain }) => {
    try{
    
      const currentNetwork = hre.network
      const name = currentNetwork.name
      
      console.log(`Deploying Bridgerton contract to ${name} network...`)

      let stargateRouter = addresses[name]
      console.log("Using Strargate router", stargateRouter)

      const Bridgerton = await ethers.getContractFactory('Bridgerton')

      console.log('Deploying')
      const bridgerton = await Bridgerton.deploy(
        stargateRouter
      )
      await bridgerton.deployed()

      console.log("Bridgerton Deployed to: ", bridgerton.address)

      //Add logic to verify contract once deployed

    } catch(error) {
      console.log(error)
    }
    
  });

