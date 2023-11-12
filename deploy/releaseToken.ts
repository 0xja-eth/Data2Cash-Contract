import { HardhatRuntimeEnvironment } from "hardhat/types";
import dotenv from "dotenv"
import {call, deployContract, getContract, mainWallet, makeContract, sendTx, setupHRE} from "../utils/contract";

dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment) {
  setupHRE(hre);

  const cid = "7074046504243040256";
  const addresses = [
    "0x94D9131ACAB9968894B877345Fcf58B8C91053ce",
    "0x40e0B51C77c57C3fAB1cdF734557bFBFFc1996E1"
  ];

  const dataSwap = await getContract("DataSwap");

  await sendTx(dataSwap.release(addresses, cid), "dataSwap.release")
}
