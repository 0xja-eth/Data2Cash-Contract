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

  const [zkProfile, isNew2] = await makeContract("ZKProfile", isNew1);
  const [proxy] = await makeContract("ZKProfileProxy", [
    zkProfile.address, "0x" // callCode
  ], isNew2);

  // const zkProfileProxy = await getContract("ZKProfile","ZKProfileProxy");

  const gov = await zkProfile.gov();
  console.log("gov", gov);

  await sendTx(zkProfile.initialize(
    hydraS1Verifier.address,
    "ZK Profile on Data2.cash",
    "https://contri.build/img/contri-img.png",
    "https://contri.build/img/contri-img.png"
  ), "zkProfile.initialize")

  const description = await zkProfile.description()
  const imageUrl = await zkProfile.imageUrl()
  const externalUrl = await zkProfile.externalUrl()

  console.log("info", {description, imageUrl, externalUrl})

}
