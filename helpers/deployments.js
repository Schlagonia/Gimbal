
deployments = [
    {
     chain: 'rinkeby',
     bridgerton: '',
     Vault: '',
     strategies: []
    },
    {
     chain: 'polygon',
     bridgerton: '',
     Vault: '',
     strategies: []
    },
    {
     chain: 'mumbai',
     bridgerton: '',
     Vault: '',
     strategies: []
    },
    {
     chain: 'opera',
     bridgerton: '',
     Vault: '',
     strategies: []
    },
    {
     chain: 'operaTestnet',
     bridgerton: '',
     Vault: '',
     strategies: []
    },
    {
     chain: 'avalanche',
     bridgerton: '',
     Vault: '',
     strategies: []
    },
    {
     chain: 'fuji',
     bridgerton: '',
     Vault: '',
     strategies: []
    },
    {
     chain: 'arbitrum',
     bridgerton: '',
     Vault: '',
     strategies: []
    },
    {
     chain: 'arbitrumRinkebyTestnet',
     bridgerton: '',
     Vault: '',
     strategies: []
    }
]

const setDeployment = (chain, contract, address) => {
    let i = getIndex(deployments, chain)
    let deployCopy = deployments

    deployCopy[i][contract] = address;
    deployments = deployCopy
    console.log(`${chain}'s ${contract} contract updated to ${deployments[i][contract]}`)
}

module.exports = {
    deployments,
    setDeployment
}