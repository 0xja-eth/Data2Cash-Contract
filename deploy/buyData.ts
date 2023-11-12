import { HardhatRuntimeEnvironment } from "hardhat/types";
import dotenv from "dotenv"
import {call, deployContract, getContract, mainWallet, makeContract, sendTx, setupHRE} from "../utils/contract";
import {BigNumber} from "ethers";

dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment) {
  setupHRE(hre);

  const cid = "7074046504243040256";
  const value = BigNumber.from(20).mul(10e12);

  const dataSwap = await getContract("DataSwap");

  await sendTx(dataSwap.buy(cid, {
    value,
    gasPrice: 40*10e9,
    gasLimit: 1000000
  }), "dataSwap.buy")
}
