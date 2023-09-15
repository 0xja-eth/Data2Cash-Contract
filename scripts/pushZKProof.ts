import { HardhatRuntimeEnvironment } from "hardhat/types";
import dotenv from "dotenv"
import hre from "hardhat";
import pushZKProof from "../deploy/pushZKProof";

dotenv.config();

pushZKProof(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
