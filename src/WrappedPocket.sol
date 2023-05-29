// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/ERC20Burnable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/access/AccessControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/extensions/draft-ERC20Permit.sol";

contract WrappedPocket is ERC20, ERC20Burnable, Pausable, AccessControl, ERC20Permit {
    bytes32 public constant PAUSER_ROLE = keccak256("PAUSER_ROLE");
    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
    uint256 public constant BASIS_POINTS = 10000;
    uint256 public constant MAX_FEE_BASIS = 300;

    bool public feeFlag;
    uint256 public feeBasis;
    address public feeCollector;

    mapping (address => uint256) private _userNonces;

    event FeeSet(bool indexed flag, uint256 indexed newFeeBasis, address indexed feeCollector);
    event FeeCollected(address indexed feeCollector, uint256 indexed amount);
    event BurnAndBridge(uint256 indexed amount, address indexed poktAddress, address indexed from);

    error UserNonce(address user, uint256 nonce);
    error FeeCollectorZero();
    error FeeBasisDust();
    error BatchMintLength();
    error MaxBasis();
    error BlockBurn();

    constructor() ERC20("Wrapped Pocket", "wPOKT") ERC20Permit("Wrapped Pocket") {
        _grantRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _grantRole(PAUSER_ROLE, msg.sender);
        _grantRole(MINTER_ROLE, msg.sender);
    }

    function pause() public onlyRole(PAUSER_ROLE) {
        _pause();
    }

    function unpause() public onlyRole(PAUSER_ROLE) {
        _unpause();
    }

    function batchMint(address[] calldata to, uint256[] calldata amount, uint256[] calldata nonce) public onlyRole(MINTER_ROLE) {
        if (to.length != amount.length || to.length != nonce.length) {
            revert BatchMintLength();
        }
        for (uint256 i = 0; i < to.length; i++) {
            _mintBatch(to[i], amount[i], nonce[i]);
        }
    }

    function burnAndBridge(uint256 amount, address poktAddress) public {
        _burn(msg.sender, amount);
        emit BurnAndBridge(amount, poktAddress, msg.sender);
    }

    function _mintBatch(address to, uint256 amount, uint256 nonce) private {
        uint256 currentNonce = _userNonces[to];
        if (nonce != currentNonce + 1) {
            revert UserNonce(to, nonce);
        }
        if (feeFlag == true) {
            amount = _collectFee(amount);
        }
        _userNonces[to] = nonce;
        _mint(to, amount);
    }

    function mint(address to, uint256 amount, uint256 nonce) public onlyRole(MINTER_ROLE) {
        uint256 currentNonce = _userNonces[to];
        if (nonce != currentNonce + 1) {
            revert UserNonce(to, nonce);
        }
        if (feeFlag == true) {
            amount = _collectFee(amount);
        }
        _userNonces[to] = nonce;
        _mint(to, amount);
    }

    function _collectFee(uint256 amount) internal returns (uint256) {
        if (amount % BASIS_POINTS != 0) {
            revert FeeBasisDust();
        }
        uint256 fee = (amount * feeBasis) / BASIS_POINTS;
        emit FeeCollected(feeCollector, fee);
        _mint(feeCollector, fee);
        return amount - fee;
    }

    function setFee(bool flag, uint256 newFee, address newCollector) public onlyRole(DEFAULT_ADMIN_ROLE) {
        if (newCollector == address(0)) {
            revert FeeCollectorZero();
        }
        if (newFee > MAX_FEE_BASIS) {
            revert MaxBasis();
        }
        feeBasis = newFee;
        feeFlag = flag;
        feeCollector = newCollector;
        emit FeeSet(flag, newFee, newCollector);
    }

    function _beforeTokenTransfer(address from, address to, uint256 amount)
        internal
        whenNotPaused
        override
    {
        super._beforeTokenTransfer(from, to, amount);
    }

    function burn(uint256) public pure override {
        revert BlockBurn();
    }

    function getUserNonce(address user) public view returns (uint256) {
        return _userNonces[user];
    }
}