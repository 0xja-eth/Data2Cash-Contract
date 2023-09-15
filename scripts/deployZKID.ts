import {HardhatRuntimeEnvironment} from "hardhat/types";
import dotenv from "dotenv"
import hre from "hardhat";
import deployZKID from "../deploy/deployZKID";

dotenv.config();

deployZKID(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
