// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWPokt {
    function batchMint(address[] calldata recipients, uint256[] calldata amounts, uint256[] calldata nonces) external;

    function mint(address recipient, uint256 amount, uint256 nonce) external;

    function hasRole(bytes32 role, address account) external returns (bool);
}

contract MintController {

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;

    IWPokt public immutable wPokt;
    address public copper;

    uint256 mintLimit = 28_500_000 ether;
    uint256 mintPerSecond = 330;

    event MintCooldownSet(uint256 newLimit, uint256 newCooldown);

    constructor(address _wPokt) {
        wPokt = IWPokt(_wPokt);
    }

    modifier onlyAdmin() {
        require(wPokt.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MintController: caller is not admin");
        _;
    }

    modifier onlyCopper() {
        require(msg.sender == copper, "MintController: caller is not copper");
        _;
    }

    function setCopper(address _copper) external onlyAdmin {
        copper = _copper;
    }

    function mintWrappedPocket(address recipient, uint256 amount, uint256 nonce) external onlyCopper {
        wPokt.mint(recipient, amount, nonce);
    }

    function batchMintWrappedPocket(address[] calldata recipients, uint256[] calldata amounts, uint256[] calldata nonces) external onlyCopper {
        wPokt.batchMint(recipients, amounts, nonces);
    }

    function setMintCooldown(uint256 newLimit, uint256 newCooldown) external onlyAdmin {
        mintLimit = newLimit;
        mintPerSecond = newCooldown;
        emit MintCooldownSet(newLimit, newCooldown);
    }

}
