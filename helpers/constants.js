
const addresses = {
    rinkeby: '0x82A0F5F531F9ce0df1DF5619f74a0d3fA31FF561',
    rinkebys : {
        stargateRouter: '0x82A0F5F531F9ce0df1DF5619f74a0d3fA31FF561',
        stargateChainId: 10001,
        usdc: '0x1717A0D5C8705EE89A8aD6E808268D6A826C97A4',
        usdt: ''
    },
    polygon : {
        stargateRouter: '0x45A01E4e04F14f7A4a6702c74187c5F6222033cd',
        stargateChainId: 9,
        usdc: '0x2791Bca1f2de4661ED88A30C99A7a9449Aa84174',
        usdt: '0xc2132D05D31c914a87C6611C10748AEb04B58e8F'
    },
    mumbai : {
        stargateRouter: '0x817436a076060D158204d955E5403b6Ed0A5fac0',
        stargateChainId: 10009,
        usdc: '0x742DfA5Aa70a8212857966D491D67B09Ce7D6ec7',
        usdt: ''
    },
    opera : {
        stargateRouter: '0xAf5191B0De278C7286d6C7CC6ab6BB8A73bA2Cd6',
        stargateChainId: 12,
        usdc: '0x04068DA6C83AFCFA0e13ba15A6696662335D5B75',
        usdt: '0x940F41F0ec9ba1A34CF001cc03347ac092F5F6B5'
    },
    operaTestnet : {
        stargateRouter: '0xa73b0a56B29aD790595763e71505FCa2c1abb77f',
        stargateChainId: 10012,
        usdc: '0x076488D244A73DA4Fa843f5A8Cd91F655CA81a1e',
        usdt: ''
    },
    avalanche : {
        stargateRouter: '0x45A01E4e04F14f7A4a6702c74187c5F6222033cd',
        stargateChainId: 6,
        usdc: '0xB97EF9Ef8734C71904D8002F8b6Bc66Dd9c48a6E',
        usdce: '0xA7D7079b0FEaD91F3e65f86E8915Cb59c1a4C664',
        usdt: '0x9702230A8Ea53601f5cD2dc00fDBc13d4dF4A8c7',
        usdte: '0xc7198437980c041c805A1EDcbA50c1Ce5db95118'
    },
    fuji : {
        stargateRouter: '0x13093E05Eb890dfA6DacecBdE51d24DabAb2Faa1',
        stargateChainId: 10006,
        usdc: '0x4A0D1092E9df255cf95D72834Ea9255132782318',
        usdt: ''
    },
    arbitrum : {
        stargateRouter: '0x53Bf833A5d6c4ddA888F69c22C88C9f356a41614',
        stargateChainId: 10,
        usdc: '0xFF970A61A04b1cA14834A43f5dE4533eBDDB5CC8',
        usdt: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9'
    },
    arbitrumRinkebyTestnet : {
        stargateRouter: '0x6701D9802aDF674E524053bd44AA83ef253efc41',
        stargateChainId: 10010,
        usdc: '0x1EA8Fb2F671620767f41559b663b86B1365BBc3d',
        usdt: ''
    }
}

const targetFloat = ''

const targetFee = '100000000000000000'

module.export = { addresses, targetFloat, targetFee }