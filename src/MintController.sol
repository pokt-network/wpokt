// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

interface IWPokt {
    function batchMint(address[] calldata recipients, uint256[] calldata amounts, uint256[] calldata nonces) external;

    function mint(address recipient, uint256 amount, uint256 nonce) external;

    function hasRole(bytes32 role, address account) external returns (bool);
}

contract MintController {
    /*//////////////////////////////////////////////////////////////
    // Immutable Storage
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    IWPokt public immutable wPokt;

    /*//////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////*/

    address public copper;

    uint256 private _currentMintLimit = 335_000 ether;
    uint256 public lastMint;

    uint256 public maxMintLimit = 335_000 ether;
    uint256 public mintPerSecond = 3.8773 ether;

    /*//////////////////////////////////////////////////////////////
    // Events and Errors
    //////////////////////////////////////////////////////////////*/

    error OverMintLimit();
    error NonAdmin();
    error NonCopper();

    event MintCooldownSet(uint256 newLimit, uint256 newCooldown);
    event NewCopper(address indexed newCopper);
    event CurrentMintLimit(uint256 indexed limit, uint256 indexed lastMint);

    constructor(address _wPokt) {
        wPokt = IWPokt(_wPokt);
    }

    /*//////////////////////////////////////////////////////////////
    // Modifiers
    //////////////////////////////////////////////////////////////*/

    /// @dev Ensure the function is only called by admin.
    /// If caller is not an admin, throws an error message.
    modifier onlyAdmin() {
        if (!wPokt.hasRole(DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert NonAdmin();
        }
        _;
    }

    /// @dev Ensure the function is only called by Copper.
    /// If caller is not Copper, throws an error message.
    modifier onlyCopper() {
        if (msg.sender != copper) {
            revert NonCopper();
        }
        _;
    }

    /*//////////////////////////////////////////////////////////////
    // Access Control
    //////////////////////////////////////////////////////////////*/

    /// @notice Changes the Copper address.
    /// @dev Can only be called by admin.
    /// @param _copper The new Copper address to be set.
    function setCopper(address _copper) external onlyAdmin {
        copper = _copper;
        emit NewCopper(_copper);
    }

    /// @notice Mints wrapped POKT tokens to a specific address.
    /// @dev Can only be called by Copper.
    /// If the amount to mint is more than the current mint limit, transaction is reverted.
    /// @param recipient The address to receive the minted tokens.
    /// @param amount The amount of tokens to mint.
    /// @param nonce A unique identifier for this mint operation.
    function mintWrappedPocket(address recipient, uint256 amount, uint256 nonce) external onlyCopper {

        uint256 remainingMintable = _enforceMintLimit(amount);

        wPokt.mint(recipient, amount, nonce);

        emit CurrentMintLimit(remainingMintable, lastMint);
    }

    /// @notice Mints wrapped POKT tokens to a list of addresses.
    /// @dev Can only be called by Copper.
    /// If the total amount to mint is more than the current mint limit, transaction is reverted.
    /// We don't check array length match because that happens at the token contract.
    /// @param recipients The addresses to receive the minted tokens.
    /// @param amounts The amounts of tokens to mint for each recipient.
    /// @param nonces Unique identifiers for each mint operation.
    function batchMintWrappedPocket(
        address[] calldata recipients,
        uint256[] calldata amounts,
        uint256[] calldata nonces
    ) external onlyCopper {
        uint256 amountTotal;

        for (uint256 i = 0; i < amounts.length;) {
            amountTotal += amounts[i];
            unchecked {
                ++i;
            }
        }

        uint256 remainingMintable = _enforceMintLimit(amountTotal);

        wPokt.batchMint(recipients, amounts, nonces);
        emit CurrentMintLimit(remainingMintable, lastMint);
    }

    /// @notice Sets the mint limit and mint per second cooldown rate.
    /// @dev Can only be called by admin.
    /// Emits a MintCooldownSet event upon successful setting.
    /// @param newLimit The new mint limit to set.
    /// @param newMintPerSecond The new mint per second cooldown rate to set.
    function setMintCooldown(uint256 newLimit, uint256 newMintPerSecond) external onlyAdmin {
        maxMintLimit = newLimit;
        mintPerSecond = newMintPerSecond;

        emit MintCooldownSet(newLimit, newMintPerSecond);
    }

    /*//////////////////////////////////////////////////////////////
    // Internal Functions
    //////////////////////////////////////////////////////////////*/

    /// @dev Updates the mint limit based on the cooldown mechanism.
    /// @param amount The amount of tokens to mint.
    /// @return The updated mint limit.
    function _enforceMintLimit(uint256 amount) internal returns (uint256) {

        uint256 timePassed = block.timestamp - lastMint;
        uint256 mintableFromCooldown = timePassed * mintPerSecond;
        uint256 previousMintLimit = _currentMintLimit;
        uint256 maxMintable = maxMintLimit;

        // We enforce that amount is not greater than the maximum mint or the current allowed by cooldown
        if (amount > mintableFromCooldown + previousMintLimit || amount > maxMintable) {
            revert OverMintLimit();
        }

        // If the cooldown has fully recovered; we are allowed to mint up to the maximum amount
        if (previousMintLimit + mintableFromCooldown >= maxMintable) {
            _currentMintLimit = maxMintable - amount;
            lastMint = block.timestamp;
            return maxMintable - amount;

        // Otherwise the cooldown has not fully recovered; we are allowed to mint up to the recovered amount
        } else {
            uint256 mintable = previousMintLimit + mintableFromCooldown;
            _currentMintLimit = mintable - amount;
            lastMint = block.timestamp;
            return mintable - amount;
        }
    }

    /*//////////////////////////////////////////////////////////////
    // View Functions
    //////////////////////////////////////////////////////////////*/
    function currentMintLimit() external view returns (uint256) {
        uint256 mintableFromCooldown = (block.timestamp - lastMint) * mintPerSecond;
        if (mintableFromCooldown + _currentMintLimit > maxMintLimit) {
            return maxMintLimit;
        } else {
            return mintableFromCooldown + _currentMintLimit;
        }
    }

    function lastMintLimit() external view returns (uint256) {
        return _currentMintLimit;
    }
}
