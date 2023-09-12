import { HardhatRuntimeEnvironment } from "hardhat/types";
import dotenv from "dotenv"
import {deployContract, getContract, makeContract, setupHRE} from "../utils/contract";

dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment) {
  setupHRE(hre);

  const [zkProfile, isNew] = await makeContract("ZKProfile");
  const [proxy] = await makeContract("ZKProfileProxy", [zkProfile.address, "0x"], isNew);

  const zkProfileProxy = await getContract("ZKProfile","ZKProfileProxy");

  const gov = await zkProfileProxy.gov();
  console.log("GOV", gov);
}
