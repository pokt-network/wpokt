const {
  PRIVATE_KEY: INPUT_PRIVATE_KEY,
  INFURA_ID,
  ETHERSCAN_API_KEY,
} = process.env;

if (!INPUT_PRIVATE_KEY) {
  throw new Error("Please set your private key in the PRIVATE_KEY env var");
}

if (!INFURA_ID) {
  throw new Error("Please set your Infura ID in the INFURA_ID env var");
}

if (!ETHERSCAN_API_KEY) {
  throw new Error(
    "Please set your Etherscan API key in the ETHERSCAN_API_KEY env var"
  );
}

const ANVIL_RPC_URL = "http://localhost:8545";

const CHAIN_IDS = {
  goerli: 5,
  mainnet: 1,
  anvil: 31337,
};

const RPC_URLS = {
  goerli: `https://goerli.infura.io/v3/${INFURA_ID}`,
  mainnet: `https://mainnet.infura.io/v3/${INFURA_ID}`,
  anvil: ANVIL_RPC_URL,
};

const PRIVATE_KEY = INPUT_PRIVATE_KEY.startsWith("0x")
  ? INPUT_PRIVATE_KEY
  : `0x${INPUT_PRIVATE_KEY}`;

module.exports = {
  CHAIN_IDS,
  RPC_URLS,
  PRIVATE_KEY,
  ANVIL_PRIVATE_KEY:
    "0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80",
  ETHERSCAN_API_KEY,
};
