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

    /// @dev Ensure the function is only called by admin.
    /// If caller is not an admin, throws an error message.
    modifier onlyAdmin() {
        require(wPokt.hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "MintController: caller is not admin");
        _;
    }

    /// @dev Ensure the function is only called by Copper.
    /// If caller is not Copper, throws an error message.
    modifier onlyCopper() {
        require(msg.sender == copper, "MintController: caller is not Copper");
        _;
    }

    /// @notice Changes the Copper address.
    /// @dev Can only be called by admin.
    /// @param _copper The new Copper address to be set.
    function setCopper(address _copper) external onlyAdmin {
        copper = _copper;
    }

    /// @notice Mints wrapped POKT tokens to a specific address.
    /// @dev Can only be called by Copper.
    /// If the amount to mint is more than the current mint limit, transaction is reverted.
    /// @param recipient The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    /// @param nonce A unique identifier for this mint operation.
    function mintWrappedPocket(address recipient, uint256 amount, uint256 nonce) external onlyCopper {
        uint256 currentMintLimit = _updateMintLimit();

        if (amount > currentMintLimit) {
            revert OverMintLimit();
        }

        wPokt.mint(recipient, amount, nonce);
    }

    /// @notice Mints wrapped POKT tokens to a list of addresses.
    /// @dev Can only be called by Copper.
    /// If the total amount to mint is more than the current mint limit, transaction is reverted.
    /// @param recipients The addresses to receive the minted tokens.
    /// @param amounts The amounts of tokens to mint for each recipient.
    /// @param nonces Unique identifiers for each mint operation.
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

    /// @notice Sets the mint limit and cooldown rate.
    /// @dev Can only be called by admin.
    /// Emits a MintCooldownSet event upon successful setting.
    /// @param newLimit The new mint limit to set.
    /// @param newCooldown The new cooldown rate to set.
    function setMintCooldown(uint256 newLimit, uint256 newCooldown) external onlyAdmin {
        mintCooldownLimit = newLimit;
        mintPerSecond = newCooldown;
        emit MintCooldownSet(newLimit, newCooldown);
    }

    /// @dev Updates the mint limit based on the cooldown mechanism.
    /// @return The updated mint limit.
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
