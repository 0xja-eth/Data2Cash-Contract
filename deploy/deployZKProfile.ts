import { HardhatRuntimeEnvironment } from "hardhat/types";
import dotenv from "dotenv"
import {call, deployContract, getContract, mainWallet, makeContract, sendTx, setupHRE} from "../utils/contract";

dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment) {
  setupHRE(hre);

  const forceDeplyZKProfile = true

  const [hydraS1Verifier, isNew1] = await makeContract("HydraS1Verifier");

  const [zkProfile, isNew2] = await makeContract("ZKProfile", isNew1 || forceDeplyZKProfile);
  const [proxy, isNew3] = await makeContract("ZKProfileProxy", [
    zkProfile.address, "0x" // callCode
  ]);

  if (!isNew3 && isNew2)
    await sendTx(proxy.upgradeTo(zkProfile.address), "proxy.upgradeTo")

  const zkProfileProxy = await getContract("ZKProfile","ZKProfileProxy");

  await call(() => zkProfileProxy.gov(), "gov");

  await sendTx(zkProfileProxy.initialize(
    hydraS1Verifier.address,
    "ZK Profile on Data2.cash",
    "https://contri.build/img/contri-img.png",
    "https://contri.build/img/contri-img.png"
  ), "zkProfile.initialize")

  const description = await call(zkProfileProxy.description())
  const imageUrl = await call(zkProfileProxy.imageUrl())
  const externalUrl = await call(zkProfileProxy.externalUrl())

  console.log("info", {description, imageUrl, externalUrl})
}
