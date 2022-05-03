//Imprt ethers into the file from whereit is. Will not be from 'hardhat
//May have to install ethers with npm install --save ethers
//const { ethers } = require("ethers");
const { ethers } = reuire('hardhat')
//Imprt the ABI json file from whatever folder is holding it
const { SavorVault } = reuire('../artifacts/contracts/SavorVault.sol/SavorVault.json')
const { ERC20 } = require('./ERC20.json')

//Constants that can be imported from another file
const currentNetwork = 'https://speedy-nodes-nyc.moralis.io/${moralisKey}/eth/rinkeby'
const usdcAddress = '0x1717A0D5C8705EE89A8aD6E808268D6A826C97A4'

async function main() {


  //The public address of the vault. Probably want to import it from a constants file
  const vaultAddress = '0x512c0bb530b27253b4644C8D5a3016CbF02ee8A3'

  //This will be either the wallet that is connected to the site or the public RPC node url
  let provider =  new ethers.providers.JsonRpcProvider(currentNetwork)

  //Example of getting the connected wallet as Signer
  //May be done differently when using moralis for the wallet
  const { ethereum } = window;

  if(!ethereum){
      return
    } else {
      console.log("We have the eth object", ethereum)
    }

  let chainId = await ethereum.request({ method: 'eth_chainId' });
  console.log('connected to ' + chainId);
  //const accounts = await ethereum.request({ method: 'eth_accounts' });
  provider = new ethers.providers.Web3Provider(ethereum);
  const signer = provider.getSigner();


  // Instantiate the contract using the address, abi and current signer
  // This variable will be used for all contract calls and can be exported/imoprted to different components so it only has to be instantiated
  const Vault = new ethers.Contract(
    vaultAddress,
    SavorVault.abi,
    signer
  )

  //Instantiate the usdc token
  const usdc = new ethers.Contract(
      usdcAddress,
      ERC20.abi,
      signer
  )

  //Example of sending a deposit into the Vault
  console.log("Depositing Funds into Vault")

  //The amount that would want to be deposited. This would be set by the user through the interface
  let amount = '100000000'

  //The user needs to approve the contract to before any deposits in order for it to work
  //Can check to see if the vault has already been improved
  let approval = await usdc.allowamce(signer.address, vaultAddress)
  if(approval < amount) {
      //Approve the contract to transfer tokens
      tx = await usdc.approve(vaultAddress, amount)
  }
  
  //Call the deposit function
  let tx = await Vault.deposit(amount)
  await tx.wait()

  console.log('Tx completed', tx)

  //Can get the current user balance at any time 
  let bal = await Vault.totalUserBalance(signer.address)
  console.log('Balance of the user ', bal)
  //Then can convert the balance to a Dollar value to display
  let usdcBalance = await Vault.convertToAssets(bal)

  //All of these values will be given with 6 decimals so will need to be converted to be displyed correctly
  // i.e. $1 USDC == 1000000
  // Use the Big Number package in ethers to convert or ethers.utils.parseUnits

}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
