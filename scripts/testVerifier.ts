import dotenv from "dotenv"
import hre from "hardhat";
import testVerifier from "../deploy/testVerifier";

dotenv.config();

testVerifier(hre).catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
