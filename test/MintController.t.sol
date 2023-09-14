// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/WrappedPocket.sol";
import "../src/MintController.sol";

contract MintControllerTest is Test {
    WrappedPocket public wPokt;
    MintController public mintController;

    address internal constant alice = address(0xAAAA);
    address internal constant bob = address(0xBBBB);
    address internal constant copperAddress = address(0xC09932);
    address internal constant bobPocket = address(0xB0BB);
    address internal constant DEVADDR = address(0xBEEF);
    address internal constant FEE_COLLECTOR = address(0xFEEE);
    address internal constant MINTER = address(0x1337);
    address internal constant PAUSER = address(0x1111);

    address[] internal validAddressAsc;
    address[] internal validAddressDesc;
    uint256[] internal privKeyAsc;
    uint256[] internal privKeyDesc;

    string internal constant _NAME = "MintController";
    string internal constant _VERSION = "1";

    bytes32 private constant _TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    bytes32 internal _hashedName;
    bytes32 internal _hashedVersion;
    uint256 internal _cachedChainId;
    bytes32 internal _cachedDomainSeparator;
    address internal _cachedControllerAddress;

    event MintCooldownSet(uint256 newLimit, uint256 newCooldown);
    event NewValidator(address indexed validator);
    event RemovedValidator(address indexed validator);
    event CurrentMintLimit(uint256 indexed limit, uint256 indexed lastMint);
    event SignerThresholdSet(uint256 indexed ratio);

    function addValidator(address newSigner) public {
        vm.startPrank(DEVADDR);
        mintController.addValidator(newSigner);
        vm.stopPrank();
    }

    function addValidators(address[] memory newSigners) public {
        vm.startPrank(DEVADDR);
        for (uint256 i = 0; i < newSigners.length; i++) {
            mintController.addValidator(newSigners[i]);
        }
        vm.stopPrank();
    }

    function buildValidatorArrayAscending(uint256 quantity) public {
        uint256[] memory privateKeyArrayAscending = new uint256[](quantity);
        address[] memory validatorArrayAscending = new address[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            address newSignerAddress = vm.addr(i + 1);
            validatorArrayAscending[i] = newSignerAddress;
            privateKeyArrayAscending[i] = i + 1;
        }
        for (uint256 i = 0; i < quantity; i++) {
            for (uint256 j = 0; j < quantity - i - 1; j++) {
                if (validatorArrayAscending[j] > validatorArrayAscending[j + 1]) {
                    address tempAddress = validatorArrayAscending[j];
                    uint256 tempKey = privateKeyArrayAscending[j];
                    validatorArrayAscending[j] = validatorArrayAscending[j + 1];
                    privateKeyArrayAscending[j] = privateKeyArrayAscending[j + 1];
                    validatorArrayAscending[j + 1] = tempAddress;
                    privateKeyArrayAscending[j + 1] = tempKey;
                }
            }
        }
        for (uint256 i = 0; i < quantity; i++) {
            privKeyAsc.push(privateKeyArrayAscending[i]);
            validAddressAsc.push(validatorArrayAscending[i]);
        }
    }

    function buildValidatorArrayDescending(uint256 quantity) public {
        uint256[] memory privateKeyArrayDescending = new uint256[](quantity);
        address[] memory validatorArrayDescending = new address[](quantity);
        for (uint256 i = 0; i < quantity; i++) {
            address newSignerAddress = vm.addr(i + 1);
            validatorArrayDescending[i] = newSignerAddress;
            privateKeyArrayDescending[i] = i + 1;
        }
        for (uint256 i = 0; i < quantity; i++) {
            for (uint256 j = 0; j < quantity - i - 1; j++) {
                if (validatorArrayDescending[j] < validatorArrayDescending[j + 1]) {
                    address tempAddress = validatorArrayDescending[j];
                    uint256 tempKey = privateKeyArrayDescending[j];
                    validatorArrayDescending[j] = validatorArrayDescending[j + 1];
                    privateKeyArrayDescending[j] = privateKeyArrayDescending[j + 1];
                    validatorArrayDescending[j + 1] = tempAddress;
                    privateKeyArrayDescending[j + 1] = tempKey;
                }
            }
        }
        for (uint256 i = 0; i < quantity; i++) {
            privKeyDesc.push(privateKeyArrayDescending[i]);
            validAddressDesc.push(validatorArrayDescending[i]);
        }
    }

    function buildMintData(address recipient, uint256 amount, uint256 nonce)
        public
        pure
        returns (MintController.MintData memory)
    {
        return MintController.MintData(recipient, amount, nonce);
    }

    function setTypeHashes() public {
        _hashedName = keccak256(bytes(_NAME));
        _hashedVersion = keccak256(bytes(_VERSION));
        _cachedChainId = block.chainid;
        _cachedControllerAddress = address(mintController);
        _cachedDomainSeparator = _buildDomainSeparator();
    }

    function _buildDomainSeparator() private view returns (bytes32) {
        return keccak256(abi.encode(_TYPE_HASH, _hashedName, _hashedVersion, block.chainid, address(mintController)));
    }

    function toTypedDataHash(bytes32 domainSeparator, bytes32 structHash) internal pure returns (bytes32 data) {
        /// @solidity memory-safe-assembly
        assembly {
            let ptr := mload(0x40)
            mstore(ptr, "\x19\x01")
            mstore(add(ptr, 0x02), domainSeparator)
            mstore(add(ptr, 0x22), structHash)
            data := keccak256(ptr, 0x42)
        }
    }

    function _hashTypedDataV4(bytes32 structHash) internal view virtual returns (bytes32) {
        return ECDSA.toTypedDataHash(_cachedDomainSeparator, structHash);
    }

    function buildSignatureAsc(MintController.MintData memory data, uint256 signerIndex)
        public
        view
        returns (bytes memory)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("MintData(address recipient,uint256 amount,uint256 nonce)"),
                    data.recipient,
                    data.amount,
                    data.nonce
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKeyAsc[signerIndex], digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        return signature;
    }

    function buildSignatureDesc(MintController.MintData memory data, uint256 signerIndex)
        public
        view
        returns (bytes memory)
    {
        bytes32 digest = _hashTypedDataV4(
            keccak256(
                abi.encode(
                    keccak256("MintData(address recipient,uint256 amount,uint256 nonce)"),
                    data.recipient,
                    data.amount,
                    data.nonce
                )
            )
        );

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(privKeyDesc[signerIndex], digest);
        bytes memory signature = abi.encodePacked(r, s, v);
        return signature;
    }

    function buildSignaturesAsc(MintController.MintData memory data) public view returns (bytes[] memory) {
        bytes[] memory signatures = new bytes[](privKeyAsc.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            signatures[i] = buildSignatureAsc(data, i);
        }
        return signatures;
    }

    function buildSignaturesDesc(MintController.MintData memory data) public view returns (bytes[] memory) {
        bytes[] memory signatures = new bytes[](privKeyDesc.length);
        for (uint256 i = 0; i < signatures.length; i++) {
            signatures[i] = buildSignatureDesc(data, i);
        }
        return signatures;
    }

    function addSigners(address[] memory signers) public {
        for (uint256 i = 0; i < signers.length; i++) {
            mintController.addValidator(signers[i]);
        }
    }

    function setUp() public {
        vm.startPrank(DEVADDR);
        wPokt = new WrappedPocket();
        wPokt.grantRole(wPokt.PAUSER_ROLE(), PAUSER);
        mintController = new MintController(address(wPokt));
        wPokt.grantRole(wPokt.MINTER_ROLE(), address(mintController));
        setTypeHashes();
        buildValidatorArrayAscending(10);
        buildValidatorArrayDescending(10);
        addSigners(validAddressAsc);
        mintController.setSignerThreshold(7);
        vm.stopPrank();
    }

    function testWPOKTSet() public {
        address expected = address(wPokt);
        address actual = address(mintController.wPokt());
        assertEq(expected, actual);
    }

    function testStartingMintLimit() public {
        uint256 expected = 335_000 ether;
        uint256 actual = mintController.currentMintLimit();
        assertEq(expected, actual);
    }

    function testStartingMintCooldownLimit() public {
        uint256 expected = 335_000 ether;
        uint256 actual = mintController.maxMintLimit();
        assertEq(expected, actual);
    }

    function testStartingMintPerSecond() public {
        uint256 expected = 3.8773 ether;
        uint256 actual = mintController.mintPerSecond();
        assertEq(expected, actual);
    }

    function testStartingLastMint() public {
        uint256 expected = 0;
        uint256 actual = mintController.lastMint();
        assertEq(expected, actual);
    }

    function testStartingLastMintLimit() public {
        uint256 expected = 335_000 ether;
        uint256 actual = mintController.lastMintLimit();
        assertEq(expected, actual);
    }

    function testAddValidator() public {
        vm.startPrank(DEVADDR);
        mintController.addValidator(bob);
        vm.stopPrank();
        bool expected = true;
        bool actual = mintController.validators(bob);
        assertEq(expected, actual);
    }

    function testAddValidatorNonAdminFail() public {
        vm.startPrank(alice);
        vm.expectRevert(MintController.NonAdmin.selector);
        mintController.addValidator(bob);
    }

    function testAddValidatorNonZeroFail() public {
        vm.startPrank(DEVADDR);
        vm.expectRevert(MintController.NonZero.selector);
        mintController.addValidator(address(0));
    }

    function testAddValidatorInvalidAddValidatorFail() public {
        vm.startPrank(DEVADDR);
        vm.expectRevert(MintController.InvalidAddValidator.selector);
        mintController.addValidator(validAddressAsc[0]);
    }

    function testAddValidatorNewValidatorEvent() public {
        vm.startPrank(DEVADDR);
        vm.expectEmit(true, false, false, false);
        emit NewValidator(bob);
        mintController.addValidator(bob);
    }

    function testRemoveValidator() public {
        vm.startPrank(DEVADDR);
        mintController.removeValidator(validAddressAsc[0]);
        vm.stopPrank();
        bool expected = false;
        bool actual = mintController.validators(validAddressAsc[0]);
        assertEq(expected, actual);
    }

    function testRemoveValidatorNonZeroFail() public {
        vm.startPrank(DEVADDR);
        vm.expectRevert(MintController.NonZero.selector);
        mintController.removeValidator(address(0));
    }

    function testRemoveValidatorBelowMinThresholdFail() public {
        vm.startPrank(DEVADDR);
        mintController.removeValidator(validAddressAsc[0]);
        mintController.removeValidator(validAddressAsc[1]);
        mintController.removeValidator(validAddressAsc[2]);
        vm.expectRevert(MintController.BelowMinThreshold.selector);
        mintController.removeValidator(validAddressAsc[3]);
    }

    function testRemoveValidatorInvalidRemoveValidator() public {
        vm.startPrank(DEVADDR);
        mintController.removeValidator(validAddressDesc[0]);
        vm.expectRevert(MintController.InvalidRemoveValidator.selector);
        mintController.removeValidator(validAddressDesc[0]);
    }

    function testRemoveValidatorNonAdminFail() public {
        vm.startPrank(alice);
        vm.expectRevert(MintController.NonAdmin.selector);
        mintController.removeValidator(validAddressAsc[0]);
    }

    function testRemoveValidatorRemovedValidatorEvent() public {
        vm.startPrank(DEVADDR);
        vm.expectEmit(true, false, false, false);
        emit RemovedValidator(validAddressAsc[0]);
        mintController.removeValidator(validAddressAsc[0]);
    }

    function testSetSignerThreshold() public {
        vm.startPrank(DEVADDR);
        mintController.setSignerThreshold(5);
        uint256 expected = 5;
        uint256 actual = mintController.signerThreshold();
        assertEq(expected, actual);
    }

    function testSetSignerThresholdInvalidSignatureRatioFail() public {
        vm.startPrank(DEVADDR);
        vm.expectRevert(MintController.InvalidSignatureRatio.selector);
        mintController.setSignerThreshold(11);
    }

    function testSetSignerThresholdSignerThresholdSetEvent() public {
        vm.startPrank(DEVADDR);
        vm.expectEmit(true, false, false, false);
        emit SignerThresholdSet(5);
        mintController.setSignerThreshold(5);
    }

    function testMintWrappedPocket() public {
        MintController.MintData memory mintData = buildMintData(alice, 100 ether, 1);
        bytes[] memory signatures = buildSignaturesAsc(mintData);
        mintController.mintWrappedPocket(mintData, signatures);
        uint256 expected = 100 ether;
        uint256 actual = wPokt.balanceOf(alice);
        assertEq(expected, actual);
    }

    function testMintWrappedPocketInvalidSignaturesFail() public {
        MintController.MintData memory mintData = buildMintData(alice, 100 ether, 1);
        bytes[] memory signatures = buildSignaturesDesc(mintData);
        vm.expectRevert(MintController.InvalidSignatures.selector);
        mintController.mintWrappedPocket(mintData, signatures);
    }

    function testMintWrappedPocketLimit() public {
        uint256 oldLimit = mintController.currentMintLimit();
        MintController.MintData memory mintData = buildMintData(alice, 100 ether, 1);
        bytes[] memory signatures = buildSignaturesAsc(mintData);
        mintController.mintWrappedPocket(mintData, signatures);
        uint256 expected = 100 ether;
        uint256 actual = wPokt.balanceOf(alice);
        assertEq(expected, actual);
        expected = oldLimit - 100 ether;
        actual = mintController.currentMintLimit();
        assertEq(expected, actual);
    }

    function testMintWrappedPocketLimitFail() public {
        uint256 mintLimit = mintController.currentMintLimit();
        uint256 amountOverLimit = mintLimit + 1 ether;
        MintController.MintData memory mintData = buildMintData(alice, amountOverLimit, 1);
        bytes[] memory signatures = buildSignaturesAsc(mintData);
        vm.expectRevert(MintController.OverMintLimit.selector);
        mintController.mintWrappedPocket(mintData, signatures);
    }

    function testMintWrappedPocketEvent() public {
        MintController.MintData memory mintData = buildMintData(alice, 100 ether, 1);
        bytes[] memory signatures = buildSignaturesAsc(mintData);
        vm.expectEmit(true, false, false, false);
        emit CurrentMintLimit(335_000 ether - 100 ether, block.timestamp);
        mintController.mintWrappedPocket(mintData, signatures);
    }

    function testSetMintCooldown() public {
        vm.startPrank(DEVADDR);
        mintController.setMintCooldown(100_000 ether, 10 ether);
        uint256 expected = 100_000 ether;
        uint256 actual = mintController.maxMintLimit();
        assertEq(expected, actual);
        expected = 10 ether;
        actual = mintController.mintPerSecond();
        assertEq(expected, actual);
    }

    function testSetMintCooldownEvent() public {
        vm.startPrank(DEVADDR);
        vm.expectEmit(true, false, false, false);
        emit MintCooldownSet(100_000 ether, 10 ether);
        mintController.setMintCooldown(100_000 ether, 10 ether);
    }

    function testSetMintCooldownFail() public {
        vm.startPrank(alice);
        vm.expectRevert(MintController.NonAdmin.selector);
        mintController.setMintCooldown(100_000 ether, 10 ether);
    }

    function testFullCooldown() public {
        vm.startPrank(copperAddress);
        uint256 mintLimit = mintController.currentMintLimit();
        MintController.MintData memory mintData = buildMintData(alice, mintLimit, 1);
        bytes[] memory signatures = buildSignaturesAsc(mintData);
        mintController.mintWrappedPocket(mintData, signatures);
        uint256 expected = 0;
        uint256 actual = mintController.currentMintLimit();
        assertEq(expected, actual);
        vm.warp(block.timestamp + 2 days);
        expected = 335_000 ether;
        actual = mintController.currentMintLimit();
        assertEq(expected, actual);
    }

    function testPartialCooldown() public {
        vm.startPrank(copperAddress);
        uint256 mintLimit = mintController.currentMintLimit();
        MintController.MintData memory mintData = buildMintData(alice, mintLimit, 1);
        bytes[] memory signatures = buildSignaturesAsc(mintData);
        mintController.mintWrappedPocket(mintData, signatures);
        uint256 expected = 0;
        uint256 actual = mintController.currentMintLimit();
        assertEq(expected, actual);
        vm.warp(block.timestamp + 6 hours);
        uint256 mintPerSecond = mintController.mintPerSecond();
        expected = mintPerSecond * 6 hours;
        actual = mintController.currentMintLimit();
        assertEq(expected, actual);
    }

    function testPartialCooldownMint() public {
        vm.startPrank(copperAddress);
        uint256 mintLimit = mintController.currentMintLimit();
        MintController.MintData memory mintData = buildMintData(alice, mintLimit, 1);
        bytes[] memory signatures = buildSignaturesAsc(mintData);
        mintController.mintWrappedPocket(mintData, signatures);
        uint256 expected = 0;
        uint256 actual = mintController.currentMintLimit();
        assertEq(expected, actual);
        vm.warp(block.timestamp + 6 hours);
        uint256 mintPerSecond = mintController.mintPerSecond();
        expected = mintPerSecond * 6 hours;
        actual = mintController.currentMintLimit();
        assertEq(expected, actual);
        mintData = buildMintData(bob, expected, 1);
        signatures = buildSignaturesAsc(mintData);
        mintController.mintWrappedPocket(mintData, signatures);
        actual = wPokt.balanceOf(bob);
        assertEq(expected, actual);
    }
}
