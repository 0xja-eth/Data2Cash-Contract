import { HardhatUserConfig } from "hardhat/config";
import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-etherscan";
import "@matterlabs/hardhat-zksync-toolbox";

import "@typechain/hardhat";

import "hardhat-preprocessor";
import * as fs from "fs";
import dotenv from "dotenv"

dotenv.config();

function getRemappings() {
  return fs
    .readFileSync("remappings.txt", "utf8")
    .split("\n")
    .filter(Boolean) // remove empty lines
    .map((line) => line.trim().split("="));
}

const config: HardhatUserConfig = {
  mocha: {
    timeout: 120000,
  },

  zksolc: {
    version: "1.3.10",
    compilerSource: "binary",
    settings: {
      // optional. Ignored for compilerSource "docker". Can be used if compiler is located in a specific folder
      compilerPath: process.env.ZK_SOLC_COMPILER_PATH,
      libraries: {}, // optional. References to non-inlinable libraries
      isSystem: false, // optional.  Enables Yul instructions available only for zkSync system contracts and libraries
      forceEvmla: false, // optional. Falls back to EVM legacy assembly if there is a bug with Yul
      optimizer: {
        enabled: true, // optional. True by default
        mode: '3' // optional. 3 by default, z to optimize bytecode size
      }
    }
  },

  solidity: {
    version: "0.8.12",
    settings: {
      optimizer: {
        enabled: true,
        runs: 10
      }
    }
  },

  defaultNetwork: "dev",
  networks: {
    // hardhat: {
    // },
    dev: {
      chainId: 270,
      url: process.env.DEVNET_RPC_URL, // The testnet RPC URL of zkSync Era network.
      accounts: [process.env.DEVNET_PRIVATE_KEY || process.env.PRIVATE_KEY],
      ethNetwork: process.env.DEVNET_ETH_NETWORK,
      zksync: true,
      allowUnlimitedContractSize: true
    },
    test: {
      chainId: 280,
      url: process.env.TESTNET_RPC_URL,
      accounts: [process.env.TESTNET_PRIVATE_KEY || process.env.PRIVATE_KEY],
      ethNetwork: process.env.TESTNET_ETH_NETWORK,
      zksync: true,
      verifyURL: process.env.TESTNET_VERIFY_URL
    },
    main: {
      chainId: 324,
      url: process.env.MAINNET_RPC_URL,
      accounts: [process.env.MAINNET_PRIVATE_KEY || process.env.PRIVATE_KEY],
      ethNetwork: process.env.MAINNET_ETH_NETWORK,
      zksync: true,
      // Verification endpoint for Goerli
      verifyURL: process.env.MAINNET_VERIFY_URL
    }
  },

  // 集成Foundry
  preprocess: {
    eachLine: (hre) => ({
      transform: (line: string) => {
        if (line.match(/^\s*import /i)) {
          for (const [from, to] of getRemappings()) {
            if (line.includes(from)) {
              line = line.replace(from, to);
              break;
            }
          }
        }
        return line;
      },
    }),
  },
  paths: {
    sources: "./contracts",
    cache: "./cache_hardhat",
  },
};

export default config;
