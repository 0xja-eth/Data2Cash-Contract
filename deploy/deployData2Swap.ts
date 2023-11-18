import { HardhatRuntimeEnvironment } from "hardhat/types";
import dotenv from "dotenv"
import {call, deployContract, getContract, mainWallet, makeContract, sendTx, setupHRE} from "../utils/contract";
import {BigNumber} from "ethers";

dotenv.config();

const TagPrices = {
  "97": { // BSC Testnet - BNB
    "7074046504243040256": BigNumber.from(10).mul(10e13), // Early Adopter
    "7086575438692093952": BigNumber.from(15).mul(10e13), // Active ETH User
    "7093087508845563904": BigNumber.from(12).mul(10e13), // QuestN User
    "7098147946901803008": BigNumber.from(25).mul(10e13)  // VIP3 SBT User
  },
  "534351": { // Scroll Testnet - ETH
    "7074046504243040256": BigNumber.from(10).mul(10e12), // Early Adopter
    "7086575438692093952": BigNumber.from(20).mul(10e12), // Active ETH User
    "7093087508845563904": BigNumber.from(24).mul(10e12), // QuestN User
    "7098147946901803008": BigNumber.from(30).mul(10e12)  // VIP3 SBT User
  }
}

export default async function (hre: HardhatRuntimeEnvironment) {
  setupHRE(hre);

  const force = false;

  const tagPrices = TagPrices[hre.network.config.chainId];

  const zkProfileProxy = await getContract("ZKProfile","ZKProfileProxy");

  const [dataSwap] = await makeContract("Data2Swap",
    [zkProfileProxy.address], force);
  // const [dataSwap] = await makeContract("Data2SwapERC1155", force);

  for (const cid in tagPrices) {
    const price = await dataSwap.tagPrices(cid)
    if (price.eq(tagPrices[cid])) continue;

    await sendTx(dataSwap.setupPrice(cid, tagPrices[cid]), "dataSwap.setupPrice")
  }
}
