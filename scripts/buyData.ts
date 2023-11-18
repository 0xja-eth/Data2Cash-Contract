import dotenv from "dotenv"
import hre from "hardhat";
import deployDataSwap from "../deploy/deployData2Swap";
import buyData from "../deploy/buyData";

dotenv.config();

buyData(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
