import "ethers";
import dotenv from "dotenv";

dotenv.config();

// connect to blockchain
const matic_provider = process.env.PROVIDER_MATIC;
const bsc_provider = process.env.PROVIDER_BSC;
const key = process.env.PRIVATE_KEY;

// bridge smart contracts
const matic_contract_addr = process.env.MATIC_CONTRACT_ADDR;
const bsc_contract_addr = process.env.BSC_CONTRACT_ADDR;

// token addresses
const tokenBsc = process.env.TOKEN_BSC;
const tokenMatic = process.env.TOKEN_MATIC;

// abi
import bscAbi from "../bin/contracts/Account.json";
