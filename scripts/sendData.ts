import dotenv from "dotenv"
import hre from "hardhat";
import deployDataSwap from "../deploy/deployDataSwap";
import buyData from "../deploy/buyData";
import sendData from "../deploy/sendData";

dotenv.config();

sendData(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
