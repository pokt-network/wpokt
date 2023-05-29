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

    uint256 public mintLimit = 28_500_000 ether;
    uint256 public mintCooldownLimit = 28_500_000 ether;
    uint256 public mintPerSecond = 330;
    uint256 public lastMint;

    error OverMintLimit();

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
        uint256 currentMintLimit = _updateMintLimit();

        if (amount > currentMintLimit) {
            revert OverMintLimit();
        }

        wPokt.mint(recipient, amount, nonce);
    }

    function batchMintWrappedPocket(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata nonces
    ) external onlyCopper {
        uint256 currentMintLimit = _updateMintLimit();
        uint256 amountTotal;

        for (uint256 i = 0; i < amounts.length; i++) {
            amountTotal += amounts[i];
        }

        if (amountTotal > currentMintLimit) {
            revert OverMintLimit();
        }

        wPokt.batchMint(recipients, amounts, nonces);
    }

    function setMintCooldown(uint256 newLimit, uint256 newCooldown) external onlyAdmin {
        mintCooldownLimit = newLimit;
        mintPerSecond = newCooldown;
        emit MintCooldownSet(newLimit, newCooldown);
    }

    function _updateMintLimit() internal returns (uint256) {
        uint256 timePassed = block.timestamp - lastMint;
        uint256 mintFromCooldown = timePassed * mintPerSecond;
        uint256 currentMintLimit = mintLimit;

        if (mintFromCooldown + currentMintLimit > mintCooldownLimit) {
            mintLimit = mintCooldownLimit;
            lastMint = block.timestamp;
            return mintLimit;
        } else {
            mintLimit += mintFromCooldown;
            lastMint = block.timestamp;
            return mintLimit;
        }
    }
}
