import dotenv from "dotenv"
import hre from "hardhat";
import deployDataSwap from "../deploy/deployDataSwap";

dotenv.config();

deployDataSwap(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
