import { HardhatRuntimeEnvironment } from "hardhat/types";
import dotenv from "dotenv"
import {deployContract, getContract, mainWallet, makeContract, sendTx, setupHRE} from "../utils/contract";

dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment) {
  setupHRE(hre);

  // const address = mainWallet().address

  // const initializeCode = "0x8129fc1c"
  // const callCode = `${initializeCode}${address}`

  const [hydraS1Verifier, isNew1] = await makeContract("HydraS1Verifier");

  const [zkid] = await makeContract("ZKID", [
    hydraS1Verifier.address,
    "ZKProfile", "ZKP",
    "ZK Profile on Data2.cash",
    "https://contri.build/img/contri-img.png",
    "https://contri.build/img/contri-img.png"
  ]);

  const description = await zkid.description()
  const imageUrl = await zkid.imageUrl()
  const externalUrl = await zkid.externalUrl()

  console.log("info", {description, imageUrl, externalUrl})

}
