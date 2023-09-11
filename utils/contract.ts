import {Deployer} from "@matterlabs/hardhat-zksync-deploy";
import {Contract, Provider, Wallet} from "zksync-web3";
import {TransactionResponse} from "@ethersproject/abstract-provider";
import {HardhatRuntimeEnvironment} from "hardhat/types";
import {getContractFactory} from "@nomiclabs/hardhat-ethers/types";
import * as fs from "fs";

import dotenv from "dotenv"

dotenv.config();

const RetryCount = 15;

// region HRE环境初始化
export let hre: HardhatRuntimeEnvironment
export let wallets: Wallet[] = []
export let deployer: Deployer
export let provider: Provider

export function chainId() { return hre.network.config.chainId }
export function mainWallet() { return wallets[0] }
export function walletAddresses() { return wallets.map(w => w.address) }

export function setupHRE(_hre: HardhatRuntimeEnvironment) {
  hre = _hre;
  provider = new Provider(hre.network.config["url"])
  if (hre.network.config.accounts instanceof Array)
    wallets = hre.network.config.accounts.map(a => new Wallet(a, provider));

  if (mainWallet()) deployer = new Deployer(hre, mainWallet());
}

// endregion

// region Contract Cache

export type Network = "dev" | "test" | "main";
export type ContractCache = {
  [ChainId in number]: {[CacheName: string]: string}
  // {[ChainId]: {[CacheName]: Address}}
}
const ContractCacheFile = process.env.CONTRACT_CACHE_FILE;

let _contractData: ContractCache;
export function getContractCache() {
  if (!_contractData)
    try {
      _contractData = JSON.parse(fs.readFileSync(ContractCacheFile, "utf-8"));
    } catch (e) {
      console.error("Get ContractData Error!", e);
      _contractData = {}
    }
  return _contractData;
}
export function getAddress(chainId: number, name: string) {
  return getContractCache()[chainId]?.[name];
}
export function saveAddress(chainId: number, name: string, address: string) {
  const contractCache = getContractCache();
  contractCache[chainId] ||= {};
  contractCache[chainId][name] = address;
  saveContractCache();
}
export function saveContractCache() {
  fs.writeFileSync(ContractCacheFile, JSON.stringify(_contractData))
}

// endregion

export async function deployContract(
  name: string, args: any[] = [], cacheName?: string, label?: string): Promise<Contract> {
  const artifact = await deployer.loadArtifact(name);
  cacheName ||= name;

  const info = label ? `${name}: ${label}` : name;
  const argStr = args.map(a => a.toString()).join(",") || "no args";
  console.info(`Deploying ${info} with ${argStr}`)

  let cnt = 0, res: Contract;
  while (true) {
    try {
      res = await deployer.deploy(artifact, args);
      break;
    } catch (e) {
      console.error("... Error!", e);
      if (++cnt < RetryCount)
        console.info(`Retrying... (${cnt}/${RetryCount})`);
      else {
        console.error(`No retry count! Transaction is failed!`);
        throw e;
      }
    }
  }
  const nameStr = cacheName == name ? name : `${cacheName}(${name})`;
  console.info(`... Completed! Contract ${nameStr}: ${res.address}`)

  saveAddress(hre.network.config.chainId, cacheName, res.address);

  return res;
}

export async function getContract(name: string, cacheName?: string, address?: string) {
  const res = await findContract(name, cacheName, address);
  const nameStr = cacheName == name ? name : `${cacheName}(${name})`;
  if (!res) throw `${nameStr} is not found!`
  return res;
}
export async function findContract(name: string, cacheName?: string, address?: string) {
  cacheName ||= name;
  const nameStr = cacheName == name ? name : `${cacheName}(${name})`;
  console.info(`Getting ${nameStr} from ${address || "cache"}`)

  const hasAddress = !!address;
  address ||= getAddress(chainId(), cacheName);

  if (!address) return null;
  if (!hasAddress) console.log(`... Cached address of ${nameStr} is ${address}`);

  const contractFactory = await hre.ethers.getContractFactory(name);
  const res = contractFactory.attach(address);

  console.info(`... Completed!`);

  return res;
}
export async function getOrDeployContract(
  name: string, cacheNameOrArgs?: string | any[], args?: any[]): Promise<[Contract, boolean]> {
  args = cacheNameOrArgs instanceof Array ? cacheNameOrArgs : args;
  const cacheName = typeof cacheNameOrArgs == "string" ? cacheNameOrArgs : name;

  const nameStr = cacheName == name ? name : `${cacheName}(${name})`;
  console.info(`Getting ${nameStr} from cache, deploy if not exist`)

  const address = getAddress(chainId(), cacheName);
  if (!address) return [await deployContract(name, args, cacheName), true];
  console.log(`... Cached address of ${nameStr} is ${address}`);

  const contractFactory = await hre.ethers.getContractFactory(name);
  const res = contractFactory.attach(address).connect(mainWallet());

  console.info(`... Completed!`);

  return [res, false];
}

// Make = Get or deploy
export async function makeContract(
  name: string, forceDeployOrCacheNameOrArgs: boolean | string | any[] = false,
  forceDeployOrArgs: boolean | any[] = false, forceDeploy = false): Promise<[Contract, boolean]> {
  const cacheName = typeof forceDeployOrCacheNameOrArgs == "string" ?
    forceDeployOrCacheNameOrArgs : name;
  const args = forceDeployOrCacheNameOrArgs instanceof Array ?
    forceDeployOrCacheNameOrArgs :
    forceDeployOrArgs instanceof Array ?
      forceDeployOrArgs : [];
  forceDeploy = typeof forceDeployOrCacheNameOrArgs == "boolean" ?
    forceDeployOrCacheNameOrArgs :
    typeof forceDeployOrArgs == "boolean" ?
      forceDeployOrArgs : forceDeploy;

  return forceDeploy ?
    [await deployContract(name, args, cacheName), true] :
    getOrDeployContract(name, cacheName, args);
}

export async function ifAddressNeq(
  contract: Contract, keys: string[] | string, vals: string[] | string) {
  return ifContract(contract, keys, vals,
    (val, tgt) => val.toLowerCase() != tgt.toLowerCase());
}
export async function ifAddressEq(
  contract: Contract, keys: string[] | string, vals: string[] | string) {
  return ifContract(contract, keys, vals,
    (val, tgt) => val.toLowerCase() == tgt.toLowerCase());
}
export async function ifContract(
  contract: Contract, keys: string[] | string, vals: string[] | string,
  predicate: (val, tgt) => boolean = (val, tgt) => val == tgt) {
  if (typeof keys == "string") keys = [keys];
  if (typeof vals == "string") vals = [vals];

  return (await Promise.all(keys.map(
    async (k, i) => predicate(await contract[k](), vals[i])
  ))).every(r => r);
}

export async function sendTx(
  txPromise: Promise<TransactionResponse> | (() => Promise<TransactionResponse>),
  label?: string, confirmations = 2) {
  if (txPromise instanceof Function) {
    let cnt = 0;
    while (true) {
      try {
        return await sendTx(txPromise(), label, confirmations);
      } catch (e) {
        console.error("... Error!", e);
        if (++cnt < RetryCount)
          console.info(`Retrying... (${cnt}/${RetryCount})`);
        else {
          console.error(`No retry count! Transaction is failed!`);
          throw e;
        }
      }
    }
  } else {
    console.info(`Sending ${label}...`)
    const res = await txPromise;
    await res.wait(confirmations)
    console.info(`... Sent! ${res.hash}`)
    return res
  }
}

export async function reportGasUsed(provider: Provider, tx, label) {
  const { gasUsed } = await provider.getTransactionReceipt(tx.hash)
  console.info(label, gasUsed.toString())
  return gasUsed
}

export async function getBlockTime(provider) {
  const blockNumber = await provider.getBlockNumber()
  const block = await provider.getBlock(blockNumber)
  return block.timestamp
}
