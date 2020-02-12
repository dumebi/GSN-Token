require('dotenv').config();
const HDWalletProvider = require('@truffle/hdwallet-provider');

module.exports = {
  // See <http://truffleframework.com/docs/advanced/configuration>
  // to customize your Truffle configuration!
  networks: {
    ganache: {
      provider() {
        return new HDWalletProvider(`${process.env.GANACHE_KEY}`, `${process.env.GANACHE}`, 0, 5)
      },
      network_id: '*', // Match any network id
      gas: 4612388, // Block Gas Limit same as latest on Mainnet https://ethstats.net/
      gasPrice: 100000000
      // allowUnlimitedContractSize: true
    },
    geth: {
      host: 'localhost',
      port: 8545,
      network_id: '*',
      gas: 4612388,
      gasPrice: 100000000
    },
    ropsten: {
      provider() {
        return new HDWalletProvider(`${process.env.METAMASK_KEY}`, `${process.env.INFURA_ROPSTEN}`, 0, 5)
      },
      network_id: 3,
      gas: 8000000
    },
    rinkleby: {
      provider() {
        return new HDWalletProvider(`${process.env.METAMASK_KEY}`, `${process.env.INFURA_RINKLEBY}`, 0, 5)
      },
      network_id: 4,
      gas: 8000000
    }
  },
  compilers: {
    solc: {
      version: '0.5.7',
      // docker: false,
      // settings: {
      //   optimizer: {
      //     enabled: true,
      //     runs: 200
      //   },
      //   evmVersion: 'byzantium'
      // }
    }
  },
};
