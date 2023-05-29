// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWPokt {

    function batchMint(address[] calldata recipients, uint256[] calldata amounts, uint256[] calldata nonces) external;

    function mint(address recipient, uint256 amount, uint256 nonce) external;

    function hasRole(bytes32 role, address account) external returns (bool);
}

contract MintController {

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    IWPokt immutable public wPokt;

    constructor(address _wPokt) {
        wPokt = IWPokt(_wPokt);
    }

    modifier onlyAdmin() {
        require(wPokt.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MintController: caller is not admin");
        _;
    }

}