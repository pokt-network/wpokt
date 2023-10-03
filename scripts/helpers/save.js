const path = require("path");
const fs = require("fs");

const addressesPath = "../../addresses.json";

const saveContractData = (targetNetwork, newContractData) => {
  let addresses = {};
  if (fs.existsSync(path.join(__dirname, addressesPath))) {
    addresses = require(path.join(__dirname, addressesPath));
  }
  if (!addresses[targetNetwork]) {
    addresses[targetNetwork] = [];
  }

  addresses[targetNetwork].push(newContractData);

  fs.writeFileSync(
    path.join(__dirname, addressesPath),
    JSON.stringify(addresses, null, 2) + "\n"
  );
};

module.exports.saveContractData = saveContractData;
