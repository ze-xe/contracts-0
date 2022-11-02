import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
require("dotenv").config();

const config: HardhatUserConfig = {
  networks: {
    hardhat: {
      chainId: 1337,
      blockGasLimit: 1000000000,
      allowUnlimitedContractSize: true,
      // forking: {
      //   url: "https://goerli.infura.io/v3/bb621c9372d048979f8677ba78fe41d7"
      // },
    },
    goerli: {
      url: "https://goerli.infura.io/v3/bb621c9372d048979f8677ba78fe41d7",
      accounts: ["0x" + process.env.PRIVATE_KEY],
    },
    harmony_testnet: {
      url: "https://api.s0.b.hmny.io",
      accounts: ["0x" + process.env.PRIVATE_KEY],
    },
    aurora_testnet: {
      url: "https://aurora-testnet.infura.io/v3/444730ad427e4a02913619a3e7c1d06c",
      accounts: ["0x" + process.env.PRIVATE_KEY],
    },
    bttc_donau: {
      url: 'https://pre-rpc.bt.io/',
      accounts: ["0x" + process.env.PRIVATE_KEY]
    },
    localhost:{
      url: "http://localhost:8545"
    }
  },
  solidity: {
    compilers: [
      {
        version: "0.8.6",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
          // viaIR: true,
        },
      },
    ],
  },
};

export default config;
