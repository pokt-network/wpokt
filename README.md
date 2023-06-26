# WrappedPocket Contract

The WrappedPocket contract is a smart contract for the Ethereum blockchain written in Solidity, it inherits functionalities from the ERC20, ERC20Burnable, Pausable, AccessControl, and ERC20Permit contracts from the OpenZeppelin library.

## Contract Features

1. **Minting Tokens**: Specific addresses (holding the "MINTER_ROLE") are allowed to mint new tokens to a specified address. Minting can also be done in batch to multiple addresses.
2. **Burning Tokens**: The contract allows the burning of tokens via a public function. However, unlike typical ERC20 contracts, burning is restricted to a method that allows the user to burn tokens and emits an event for bridging the amount to the Pocket blockchain.
3. **Pause and Unpause**: The contract functions can be paused and unpaused by addresses with the "PAUSER_ROLE".
4. **Fees**: The contract has a fee mechanism in place, with the possibility to enable/disable fees and set the fee amount. Fees are deducted during the minting process and are sent to a specified fee collector address.
5. **Access Control**: Access control is implemented using roles, with the "DEFAULT_ADMIN_ROLE" having permission to set fees, the "PAUSER_ROLE" able to pause and unpause the contract, and the "MINTER_ROLE" permitted to mint tokens.

## Methods

- `burnAndBridge(uint256 amount, address poktAddress)`: Allows a user to burn their tokens and emits an event to bridge the amount to the Pocket blockchain.
- `pause()`: Allows an account with the "PAUSER_ROLE" to pause the contract functions.
- `unpause()`: Allows an account with the "PAUSER_ROLE" to unpause the contract functions.
- `mint(address to, uint256 amount, uint256 nonce)`: Allows an account with the "MINTER_ROLE" to mint tokens to a specific address.
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

The MintController is a Solidity smart contract that interfaces with the Wrapped Pocket (wPOKT) token contract. It provides functionality to mint new wPOKT tokens, with a cap on the amount of tokens that can be minted within a certain time frame to prevent token oversupply.

## Contract Structure

### Immutable Storage

The contract stores a constant `DEFAULT_ADMIN_ROLE` which is used for role-based access control and an instance of the `IWPokt` interface to interact with the wPOKT contract.

### State Variables

The state of the contract includes:
- `copper`: the address that has the privilege to mint new wPOKT tokens.
- `mintLimit`: the maximum number of tokens that can be minted per period.
- `mintCooldownLimit`: the limit of the cooldown period for minting operations.
- `mintPerSecond`: the rate at which the mint limit is reset.
- `lastMint`: the timestamp of the last mint operation.

### Modifiers

There are two modifiers, `onlyAdmin` and `onlyCopper`, used to restrict access to certain functions to the admin and copper roles respectively.

### Events

- `MintCooldownSet`: emitted when the mint limit and cooldown rate are changed.
- `NewCopper`: emitted when the copper address is updated.
- `CurrentMintLimit`: emitted each time tokens are minted, includes the updated mint limit and the timestamp of the last mint operation.

### Errors

- `OverMintLimit`: thrown when a mint operation attempts to exceed the current mint limit.

## Key Functions

### setCopper

Changes the address with the `copper` role, which has permission to mint tokens. Can only be called by an admin.

### mintWrappedPocket

Mints wPOKT tokens to a specific address. It first updates the current mint limit with the `_updateMintLimit` function. If the amount to be minted exceeds this limit, the transaction is reverted.

### batchMintWrappedPocket

Similar to `mintWrappedPocket`, but allows minting tokens to a batch of addresses at once. It calculates the total amount to be minted and checks this against the current mint limit.

### setMintCooldown

Allows the admin to set the mint limit and cooldown rate. The limit controls the maximum tokens that can be minted per cooldown period and the cooldown rate controls the speed at which the mint limit is reset.

### _updateMintLimit

A helper function used to calculate the current mint limit based on the cooldown mechanism.

This contract ensures that the supply of wPOKT tokens can be expanded in a controlled manner, by the address with the copper role, while preventing abuse through the mint cooldown mechanism.

---

# Tips

- The contracts are designed to use one source of truth as to the administrator of the protocol.  The DEFAULT_ADMIN_ROLE account set on the WrappedPocket token contract is the administrator of the MintController too.
- The DEFAULT_ADMIN_ROLE should always be a secure multisig with trusted Pocket Foundation and Pocket Community members as signers.
- The MintController is a separate contract because it enables the minting mechanism controller to be very simply upgraded.
- In order to upgrade the MintController; simply deploy a new version or type of the MintController contract - and call `grantRole(MINTER_ROLE, newMintControllerAddress)` on the Wrapped Pocket token contract from the DEFAULT_ADMIN_ROLE multisig.
- After upgrading the MintController; you should also call `revokeRole(MINTER_ROLE, oldMintControllerAddress)` in order to revoke MINTER_ROLE from the old contract.
- If you don't want to update the MintController contract; but you would like to change the account address which initiates the minting transactions you can call `setCopper(newMintingWalletAddress)` from the DEFAULT_ADMIN_ROLE multisig.
- There's a userNonce mapping in the Wrapped Token contract which will block any erroneous minting attempt from the backend.
- The userNonce is also helpful to prevent replay attacks in the case of upgrading to purely signature based minting.