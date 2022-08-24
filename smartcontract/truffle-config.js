const HDWalletProvider = require("@truffle/hdwallet-provider");
const fs = require("fs");
const mnemonic = fs.readFileSync(".secret").toString().trim();

var DATAHUB_API_KEY = "2b03bd451a4393f22833fbd2b4df0301";

module.exports = {
    networks: {
        development: {
            host: "localhost",
            port: 7545,
            network_id: "*",
        },
        matic_testnet: {
            provider: () =>
                new HDWalletProvider({
                  mnemonic: {
                    phrase: mnemonic,
                  },
                  providerOrUrl: `https://matic-mumbai--rpc.datahub.figment.io/apikey/${DATAHUB_API_KEY}/`,
                  chainId: 80001,
                }),
            network_id: 80001,
            confirmations: 2,
            timeoutBlocks: 200,
            skipDryRun: true,
            chainId: 80001,
        },
        bsc_testnet: {
            provider: () =>
                new HDWalletProvider({
                  mnemonic: {
                    phrase: mnemonic,
                  },
                  providerOrUrl: `https://data-seed-prebsc-2-s2.binance.org:8545/`,
                  chainId: 97,
                }),
            network_id: 97,
            confirmations: 2,
            timeoutBlocks: 200,
            skipDryRun: true,
            chainId: 97,
        },
    },
    contracts_directory: "./contracts",
    compilers: {
        solc: {
            optimizer: {
                enabled: true,
                runs: 200,
            },
        },
    },

    db: {
        enabled: false,
    },
};