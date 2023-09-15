import { HardhatRuntimeEnvironment } from "hardhat/types";
import dotenv from "dotenv"
import {deployContract, getContract, mainWallet, makeContract, sendTx, setupHRE} from "../utils/contract";

dotenv.config();

export default async function (hre: HardhatRuntimeEnvironment) {
  setupHRE(hre);

  const mintTo = "0xCAEbD06d75b5F8C77A73DF27AB56964CCc64f793"
  const snarkProof = {
    "a": [
      "7002101144037118837740043223219614170135514412638574857210279784749707302727",
      "8791579113380235302038738646697078871886185221635687070454691959769426481964"
    ],
    "b": [
      [
        "17902354447629311839046122357103472378077789922771532037442012675042551199865",
        "20069957820887957942607934553106327279471108318965188935819955174756291897765"
      ],
      [
        "7721179116715644267680769257985257272021168181079348397514745631080449178547",
        "14112788180110945299071181887405400586013717876873107502572980329770702208538"
      ]
    ],
    "c": [
      "13900104502951189662236110027633814054086582636540684754886905153219968531051",
      "7750140962946186491350961834297646024989697874367453827853238836462396934352"
    ],
    "input": [
      "1400510299504294538952206511036232102380298684832042390575113759684034559",
      "19308639107826827785894492854972598901253437608527396016441956143321994483676",
      "10131818527482207601361697335979135807647358394906828389422636174138931360284",
      "7074046504243040256",
      "20608600308552287062639513801144823528661019951152772606940899932950338940757"
    ]
  }
  const snarkProofArr = [snarkProof.a, snarkProof.b, snarkProof.c, snarkProof.input]

  const [hydraS1Verifier] = await makeContract("HydraS1Verifier");

  // const testAddition = await hydraS1Verifier.testAddition();
  // console.log("testAddition", testAddition)

  // const testScalarMul = await hydraS1Verifier.testScalarMul();
  // console.log("testScalarMul", testScalarMul)
  //
  // const verifyingKey = await hydraS1Verifier.verifyingKey();
  // console.log("verifyingKey", verifyingKey)
  //
  // const inputs = await hydraS1Verifier.makeInputValues(...snarkProofArr)
  // console.log("inputs", inputs)
  //
  // const fakeVerify = await hydraS1Verifier.fakeVerifyProof(...snarkProofArr)
  // console.log("fakeVerify", fakeVerify)

  const isVerified = await hydraS1Verifier.verifyProof(...snarkProofArr)
  console.log("isVerified", isVerified)

}
