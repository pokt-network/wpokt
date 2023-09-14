const {
  CHAIN_IDS,
  RPC_URLS,
  PRIVATE_KEY: INPUT_PRIVATE_KEY,
  ANVIL_PRIVATE_KEY,
  ETHERSCAN_API_KEY,
} = require("./helpers/networks");
const { run, runWithResult } = require("./helpers/run");
const { saveContractData } = require("./helpers/save");

const [targetNetwork] = process.argv.slice(2);

if (!targetNetwork) {
  throw new Error(
    `Please specify a target network, please specify one of ${Object.keys(
      CHAIN_IDS
    ).join(", ")}`
  );
}

if (!CHAIN_IDS[targetNetwork]) {
  throw new Error(
    `Unknown target network ${targetNetwork}, please specify one of ${Object.keys(
      CHAIN_IDS
    ).join(", ")}`
  );
}

const CHAIN_ID = CHAIN_IDS[targetNetwork];
const RPC_URL = RPC_URLS[targetNetwork];
const PRIVATE_KEY =
  targetNetwork === "anvil" ? ANVIL_PRIVATE_KEY : INPUT_PRIVATE_KEY;

async function deploy() {
  console.log(`Deploying to ${targetNetwork} (${CHAIN_ID})...\n`);

  const deployOutput = run(
    `forge script scripts/Deploy.s.sol --broadcast --rpc-url ${RPC_URL} --private-key ${PRIVATE_KEY}`
  );

  if (!deployOutput.success) {
    console.log(deployOutput.error);
    process.exit(1);
  }

  const dataPath = `../broadcast/Deploy.s.sol/${CHAIN_ID}/run-latest.json`;

  const data = require(dataPath);

  console.log(`\nDeployed to ${targetNetwork} (${CHAIN_ID})`);

  let wrappedPocketContractAddress = "";
  let mintControllerContractAddress = "";

  data.transactions.forEach((tx) => {
    if (tx.contractName === "WrappedPocket" && !wrappedPocketContractAddress) {
      wrappedPocketContractAddress = tx.contractAddress;
    }
    if (
      tx.contractName === "MintController" &&
      !mintControllerContractAddress
    ) {
      mintControllerContractAddress = tx.contractAddress;
    }
  });

  if (targetNetwork !== "anvil") {
    const COMPILER_VERSION = "v0.8.20+commit.a1b79de6";

    console.log("Verifying contracts...\n");

    console.log("Verifying WrappedPocket contract...\n");

    const verifyWrappedPocketOutput = run(
      `forge verify-contract --etherscan-api-key ${ETHERSCAN_API_KEY} --chain-id ${CHAIN_ID} --compiler-version ${COMPILER_VERSION} --watch ${wrappedPocketContractAddress} WrappedPocket`
    );

    if (!verifyWrappedPocketOutput.success) {
      console.log(verifyWrappedPocketOutput.error);
      process.exit(1);
    }

    console.log("\nVerified WrappedPocket contract");

    console.log("\nVerifying MintController contract...\n");

    const verifyMintControllerOutput = run(
      `forge verify-contract --etherscan-api-key ${ETHERSCAN_API_KEY} --chain-id ${CHAIN_ID} --compiler-version ${COMPILER_VERSION} --constructor-args 0x000000000000000000000000${wrappedPocketContractAddress.slice(
        2
      )} --watch ${mintControllerContractAddress} MintController`
    );

    if (!verifyMintControllerOutput.success) {
      console.log(verifyMintControllerOutput.error);
      process.exit(1);
    }

    console.log("\nVerified MintController contract");

    console.log("\nDone verifying contracts");
  }

  console.log("\nSaving contract data...\n");

  const lastReceipt = data.receipts.pop();
  const { blockNumber, cumulativeGasUsed, effectiveGasPrice } = lastReceipt;

  const { result: commitId } = runWithResult(`git rev-parse --short HEAD`);

  const totalGasUsed = parseInt(cumulativeGasUsed, 16);
  const gasPrice = parseInt(effectiveGasPrice, 16);

  const contractData = {
    MintController: mintControllerContractAddress,
    WrappedPocket: wrappedPocketContractAddress,
    blockNumber: BigInt(blockNumber, 16).toString(),
    totalGasUsed: `${totalGasUsed} gas`,
    gasPrice: `${gasPrice / 1e9} gwei`,
    totalGasCost: `${(totalGasUsed * gasPrice) / 1e18} ETH`,
    timestamp: new Date(Date.now()).toUTCString(),
    commitRef: commitId,
  };

  console.log(
    `\nWrappedPocket contract address: ${wrappedPocketContractAddress}`
  );
  console.log(
    `MintController contract address: ${mintControllerContractAddress}`
  );
  console.log("Block number: ", contractData.blockNumber);
  console.log("Total gas used: ", contractData.cumulativeGasUsed);

  saveContractData(targetNetwork, contractData);

  console.log("\nSaved deployment data to `addresses.json`");
}

deploy().catch((error) => {
  console.error(error);
  process.exit(1);
});
