// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/utils/cryptography/EIP712.sol";

interface IWPokt {
    function batchMint(address[] calldata recipients, uint256[] calldata amounts, uint256[] calldata nonces) external;

    function mint(address recipient, uint256 amount, uint256 nonce) external;

    function hasRole(bytes32 role, address account) external returns (bool);
}

contract MintController is EIP712 {
    /*//////////////////////////////////////////////////////////////
    // Immutable Storage
    //////////////////////////////////////////////////////////////*/

    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x00;
    IWPokt public immutable wPokt;

    /*//////////////////////////////////////////////////////////////
    // State
    //////////////////////////////////////////////////////////////*/

    mapping(address => bool) public validators;
    uint256 public validatorCount;
    uint256 public signatureRatio = 50; // out of 100

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
    error InvalidSignatureRatio();
    error InvalidSignatures();

    event MintCooldownSet(uint256 newLimit, uint256 newCooldown);
    event NewValidator(address indexed validator);
    event RemovedValidator(address indexed validator);
    event CurrentMintLimit(uint256 indexed limit, uint256 indexed lastMint);
    event SignatureRatioSet(uint256 indexed ratio);

    constructor(address _wPokt) EIP712("MintController", "1") {
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

    /*//////////////////////////////////////////////////////////////
    // Access Control
    //////////////////////////////////////////////////////////////*/



    /// @notice Adds a validator to the list of validators.
    /// @dev Can only be called by admin.
    /// Emits a NewValidator event upon successful addition.
    /// @param _validator The address of the validator to add.
    function addValidator(address _validator) external onlyAdmin {
        validators[_validator] = true;
        emit NewValidator(_validator);
    }

    /// @notice Removes a validator from the list of validators.
    /// @dev Can only be called by admin.
    /// Emits a RemovedValidator event upon successful removal.
    /// @param _validator The address of the validator to remove.
    function removeValidator(address _validator) external onlyAdmin {
        validators[_validator] = false;
        emit RemovedValidator(_validator);
    }

    /// @notice Sets the signature ratio.
    /// @dev Can only be called by admin.
    /// Emits a SignatureRatioSet event upon successful setting.
    /// @param _signatureRatio The new signature ratio to set.
    function setSignatureRatio(uint256 _signatureRatio) external onlyAdmin {
        if (_signatureRatio <= 0 || _signatureRatio > 100) {
            revert InvalidSignatureRatio();
        }
        signatureRatio = _signatureRatio;
        emit SignatureRatioSet(_signatureRatio);
    }

    struct MintData {
        address recipient;
        uint256 amount;
        uint256 nonce;
    }

    /// @notice Mint wrapped POKT tokens to a specific address with a signature.
    /// @dev Can be called by anyone
    /// If the amount to mint is more than the current mint limit, transaction is reverted.
    /// @param _data The mint data to be verified.
    /// @param _signatures The signatures to be verified.
    function mintWrappedPocket(MintData calldata _data, bytes[] calldata _signatures) external {

        if (_verify(_data, _signatures) == false) {
            revert InvalidSignatures();
        }
        
        uint256 remainingMintable = _enforceMintLimit(_data.amount);
        wPokt.mint(_data.recipient, _data.amount, _data.nonce);
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

    /// @notice Verifies the mint data signature.
    /// @dev internal function to be called by mintWithSignature.
    /// @param _data The mint data to be verified.
    /// @param _signatures The signatures to be verified.
    /// @return True if the signatures are valid, false otherwise.
    function _verify(MintData calldata _data, bytes[] calldata _signatures) internal view returns (bool) {
        bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(
                keccak256("MintData(address recipient,uint256 amount,uint256 nonce)"),
                _data.recipient,
                _data.amount,
                _data.nonce
            )));

        uint256 validSignatures = 0;
        for (uint256 i = 0; i < _signatures.length; i++) {
            address signer = ECDSA.recover(digest, _signatures[i]);
            if (validators[signer]) {
                validSignatures++;
            }
        }
        return validSignatures > 0 &&  validSignatures >= signatureRatio * validatorCount / 100;
    }


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
