// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Script.sol";
import "../src/MintController.sol";
import "../src/WrappedPocket.sol";

contract Deploy is Script {
    struct NetworkConfig {
        address[] validators;
        uint256 signerThreshold;
    }

    NetworkConfig private config;

    mapping(uint256 => NetworkConfig) private chainIdToNetworkConfig;

    constructor() {
        chainIdToNetworkConfig[31337] = getAnvilEthConfig();

        config = chainIdToNetworkConfig[block.chainid];
    }

    function getAnvilEthConfig()
        internal
        pure
        returns (NetworkConfig memory anvilNetworkConfig)
    {

        address[] memory validators = new address[](3);
        validators[0] = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        validators[1] = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        validators[2] = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);

        anvilNetworkConfig = NetworkConfig({
          validators: validators,
          signerThreshold: 2
        });
    }

    function run() external {
        vm.startBroadcast();

        WrappedPocket wpokt = new WrappedPocket();

        MintController mintController = new MintController(address(wpokt));

        for (uint256 i = 0; i < config.validators.length; ++i) {
          mintController.addValidator(config.validators[i]);
        }

        mintController.setSignerThreshold(config.signerThreshold);

        bytes32 minterRole = wpokt.MINTER_ROLE();

        wpokt.grantRole(minterRole, address(mintController));

        vm.stopBroadcast();
    }
}
