import dotenv from "dotenv"
import hre from "hardhat";
import deployDataSwap from "../deploy/deployData2Swap";

dotenv.config();

deployDataSwap(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
