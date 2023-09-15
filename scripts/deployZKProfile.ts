import dotenv from "dotenv"
import hre from "hardhat";
import deployZKProfile from "../deploy/deployZKProfile";

dotenv.config();

deployZKProfile(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
