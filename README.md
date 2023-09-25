# Halborn Audit:
# WrappedPocket Contract

The WrappedPocket contract is a smart contract for the Ethereum blockchain written in Solidity, it inherits functionalities from the ERC20, ERC20Burnable, Pausable, AccessControl, and ERC20Permit contracts from the OpenZeppelin library.

## Contract Features

1. **Minting Tokens**: Specific addresses (holding the "MINTER_ROLE") are allowed to mint new tokens to a specified address. Minting can also be done in batch to multiple addresses.  This is for minter contracts; which can be changed to extend the functionality of wPOKT.
2. **Burning Tokens**: The contract allows the burning of tokens via a public function. However, unlike typical ERC20 contracts, burning is restricted to a method that allows the user to burn tokens and emits an event for bridging the amount to a specific address on the Pocket Network blockchain.
3. **Pause and Unpause**: The contract functions can be paused and unpaused by addresses with the "PAUSER_ROLE".
4. **Fees**: The contract has a fee mechanism in place, with the possibility to enable/disable fees and set the fee amount. Fees are deducted during the minting process and are sent to a specified fee collector address.
5. **Access Control**: Access control is implemented using roles, with the "DEFAULT_ADMIN_ROLE" having permission to set fees, the "PAUSER_ROLE" able to pause and unpause the contract, and the "MINTER_ROLE" permitted to mint tokens.

## Methods

- `burnAndBridge(uint256 amount, address poktAddress)`: Allows a user to burn their tokens and emits an event to bridge the amount to the Pocket blockchain.
- `pause()`: Allows an account with the "PAUSER_ROLE" to pause the contract functions.
- `unpause()`: Allows an account with the "PAUSER_ROLE" to unpause the contract functions.
- `mint(address to, uint256 amount, uint256 nonce)`: Allows an account with the "MINTER_ROLE" to mint tokens to a specific address.  The nonce is used to prevent any identical transaction from being allowed.
- `batchMint(address[] calldata to, uint256[] calldata amount, uint256[] calldata nonce)`: Allows an account with the "MINTER_ROLE" to mint tokens in batches to multiple addresses.
- `setFee(bool flag, uint256 newFee, address newCollector)`: Allows an account with the "DEFAULT_ADMIN_ROLE" to set the fee parameters.
- `getUserNonce(address user)`: Get the current nonce for a user.
  
## Events

- `FeeSet(bool indexed flag, uint256 indexed newFeeBasis, address indexed feeCollector)`: Emitted when the fee parameters are set.
- `FeeCollected(address indexed feeCollector, uint256 indexed amount)`: Emitted when a fee is collected.
- `BurnAndBridge(uint256 indexed amount, address indexed poktAddress, address indexed from)`: Emitted when tokens are burned and bridged to the Pocket blockchain.

## Modifiers

- `onlyRole()`: Used to restrict access to functions based on the caller's role.
- `whenNotPaused()`: Used to prevent execution of functions when the contract is paused.

## Errors

The contract defines several custom errors to revert transactions under specific conditions, such as fee-related errors (e.g., `FeeBasisDust`, `MaxBasis`, `FeeCollectorZero`), batch minting errors (`BatchMintLength`), nonce errors (`UserNonce`) and burning error (`BlockBurn`).

---

# MintController Smart Contract Documentation

The MintController is a smart contract that interfaces with the Wrapped Pocket (wPOKT) token contract. It provides functionality to mint new wPOKT tokens, with a cap on the amount of tokens that can be minted within a certain time frame as a security feature.

## Contract Structure

### Immutable Storage

The contract stores a constant `DEFAULT_ADMIN_ROLE` which is used for role-based access control and an instance of the `IWPokt` interface to interact with the wPOKT contract.

### State Variables

The state of the contract includes:
- `mintLimit`: the maximum number of tokens that can be minted per period.
- `mintCooldownLimit`: the limit of the cooldown period for minting operations.
- `mintPerSecond`: the rate at which the mint limit is replenished.
- `lastMint`: the timestamp of the last mint operation.
- `validatorCount`: the total number of valid signers
- `signerThreshold`: the required number of valid signatures to initate a minting transaction

### Modifiers

Theres a single modifier, `onlyAdmin` used to restrict access to certain functions to the admin of the WrappedPocket contract.

### Events

- `MintCooldownSet`: emitted when the mint limit and cooldown rate are changed.
- `NewValidator`: emitted when a new valid validator signer address is updated.
- `RemovedValidator`: emitted when a previous validator signer is removed.
- `CurrentMintLimit`: emitted each time tokens are minted, includes the updated mint limit and the timestamp of the last mint operation.
- `SignerThresholdSet`: emitted if the required signer threshold is changed.

### Errors

- `OverMintLimit`: thrown when a mint operation attempts to exceed the current mint limit.
- `NonAdmin`: thrown when access control function is called by a non-access control address.
- `InvalidSignatureRatio`: thrown when invalid parameters are used to update the signature threshold.
- `InvalidSignatures`: thrown when the `_verify` function returns false during signature verification
- `NonZero`: returns when the zero address is used during add or remove validators.
- `BelowMinThreshold`: returns if attempting to remove a validator signer would reduce total signers below signer threshold.

## Key Functions

### mintWrappedPocket

Mints wPOKT tokens to a specific address. First it calls `_verify` which constructs an EIP712 typed data digest for the MintData parameter; then it authenticates that the array of signatures passed in; are indeed valid signatures for the MintData digest object.  The `_verify` function also requires that the integer typecasting of each address is always greater for each recovered address from the elements in the signature array.  So it will revert if more than one signature is passed into the function from a single address; and it will revert if the signatures in the array are not ascending in terms of their recovered signer addresses.  Secondly; it updates the current mint limit with the `_updateMintLimit` function. If the amount to be minted exceeds this limit, the transaction is reverted.

### setMintCooldown

Allows the admin to set the mint limit and cooldown rate. The limit controls the maximum tokens that can be minted per cooldown period and the cooldown rate controls the speed at which the mint limit is reset.

### _updateMintLimit

A helper function used to calculate the current mint limit based on the cooldown mechanism.

This contract ensures that the supply of wPOKT tokens can be expanded in a controlled manner, while preventing abuse through the mint cooldown mechanism.

### setSignerThreshold

Allows admin to change the required amount of signatures during mint transactions.

### addValidator

Admin-only function which allows a new valid signer to be added.

### removeValidator

Admin-only function which allows a valid signer to be removed.

---

# Tips

- The contracts are designed to use one source of truth as to the administrator of the protocol.  The DEFAULT_ADMIN_ROLE account set on the WrappedPocket token contract is the administrator of the MintController too.
- The DEFAULT_ADMIN_ROLE should always be a secure multisig with trusted Pocket Foundation and Pocket Community members as signers.
- The MintController is a separate contract because it enables the minting mechanism controller to be very simply upgraded.
- In order to upgrade the MintController; simply deploy a new version or type of the MintController contract - and call `grantRole(MINTER_ROLE, newMintControllerAddress)` on the Wrapped Pocket token contract from the DEFAULT_ADMIN_ROLE multisig.
- After upgrading the MintController; you should also call `revokeRole(MINTER_ROLE, oldMintControllerAddress)` in order to revoke MINTER_ROLE from the old contract.
- There's a userNonce mapping in the Wrapped Token contract which will block any erroneous minting attempt from the backend.

