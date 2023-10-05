// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.7;

import "forge-std/Script.sol";
import "../src/MintController.sol";
import "../src/WrappedPocket.sol";

contract Deploy is Script {
    struct NetworkConfig {
        address[] validators;
        uint256 signerThreshold;
        address admin;
    }

    NetworkConfig private config;

    mapping(uint256 => NetworkConfig) private chainIdToNetworkConfig;

    constructor() {
        chainIdToNetworkConfig[31337] = getAnvilEthConfig();
        chainIdToNetworkConfig[5] = getGoerliEthConfig();
        chainIdToNetworkConfig[1] = getMainnetEthConfig();

        config = chainIdToNetworkConfig[block.chainid];
    }

    function getAnvilEthConfig() internal pure returns (NetworkConfig memory anvilNetworkConfig) {
        address[] memory validators = new address[](3);
        validators[0] = address(0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266);
        validators[1] = address(0x70997970C51812dc3A010C7d01b50e0d17dc79C8);
        validators[2] = address(0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC);

        anvilNetworkConfig = NetworkConfig({validators: validators, signerThreshold: 2, admin: address(0)});
    }

    function getGoerliEthConfig() internal pure returns (NetworkConfig memory goerliNetworkConfig) {
        address[] memory validators = new address[](3);
        validators[0] = address(0x46369958d203F21528d9D18Ec12E714951d20DcD);
        validators[1] = address(0x6dd1636D5e28638D5b2eb7a21e0e697DA652AD82);
        validators[2] = address(0x5766E32b47D45ac13D27F76Fe76bd6eCDc6f359E);

        goerliNetworkConfig = NetworkConfig({
            validators: validators,
            signerThreshold: 2,
            admin: address(0x3ef8D010f76dc42e7479CF5A914ae45AdE76eb32)
        });
    }

    function getMainnetEthConfig() internal pure returns (NetworkConfig memory mainnetNetworkConfig) {
        address[] memory validators = new address[](7);

        validators[0] = address(0xBE9210d6b7A96AabcBA54ced1dC34dA7DdC4c931);
        validators[1] = address(0xDD1A209a52dA5a98F61c85e7Add9f4f2AAfa4d37);
        validators[2] = address(0x96383b08dAFD38e05566Cd6941881a503aFBFc85);
        validators[3] = address(0x974AF2Ea43b329ef27BEe5A9D8e5AF02bF4D58fB);
        validators[4] = address(0x754fFD7817E391A16c8d141029823a18e025404C);
        validators[5] = address(0x12E08268e155756012BD10163417BD04ECd22b3b);
        validators[6] = address(0x7Bf50970669D5c9fD3a8F7079C495D1Cc1C157aD);

        mainnetNetworkConfig = NetworkConfig({
            validators: validators,
            signerThreshold: 5,
            admin: address(0x2f16615234827eE4dF14d02d40C24E6a258dD360)
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

        if (config.admin != address(0)) {
            bytes32 defaultAdminRole = wpokt.DEFAULT_ADMIN_ROLE();

            bytes32 pauserRole = wpokt.PAUSER_ROLE();

            wpokt.grantRole(defaultAdminRole, config.admin);

            wpokt.grantRole(pauserRole, config.admin);

            wpokt.renounceRole(defaultAdminRole, msg.sender);
        }

        vm.stopBroadcast();
    }
}
