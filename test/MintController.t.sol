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

    event MintCooldownSet(uint256 newLimit, uint256 newCooldown);
    event NewCopper(address indexed newCopper);
    event CurrentMintLimit(uint256 indexed limit, uint256 indexed lastMint);

    function setCopperAddress() public {
        vm.startPrank(DEVADDR);
        mintController.setCopper(copperAddress);
        vm.stopPrank();
    }

    function setUp() public {
        vm.startPrank(DEVADDR);
        wPokt = new WrappedPocket();
        wPokt.grantRole(wPokt.PAUSER_ROLE(), PAUSER);
        mintController = new MintController(address(wPokt));
        wPokt.grantRole(wPokt.MINTER_ROLE(), address(mintController));
        vm.stopPrank();
    }

    function testWPOKTSet() public {
        address expected = address(wPokt);
        address actual = address(mintController.wPokt());
        assertEq(expected, actual);
    }

    function testStartingCopper() public {
        address expected = address(0);
        address actual = mintController.copper();
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

    function testSetCopper() public {
        vm.startPrank(DEVADDR);
        mintController.setCopper(copperAddress);
        address expected = copperAddress;
        address actual = mintController.copper();
        assertEq(expected, actual);
        vm.stopPrank();
    }

    function testSetCopperFail() public {
        vm.expectRevert(MintController.NonAdmin.selector);
        mintController.setCopper(copperAddress);
    }

    function testSetCopperEvent() public {
        vm.startPrank(DEVADDR);
        vm.expectEmit(true, false, false, false);
        emit NewCopper(copperAddress);
        mintController.setCopper(copperAddress);
        vm.stopPrank();
    }

    function testMintWrappedPocket() public {
        setCopperAddress();
        vm.startPrank(copperAddress);
        mintController.mintWrappedPocket(alice, 100 ether, 1);
        uint256 expected = 100 ether;
        uint256 actual = wPokt.balanceOf(alice);
        assertEq(expected, actual);
    }

    function testMintWrappedPocketLimit() public {
        setCopperAddress();
        uint256 oldLimit = mintController.currentMintLimit();
        vm.startPrank(copperAddress);
        mintController.mintWrappedPocket(alice, 100 ether, 1);
        uint256 expected = 100 ether;
        uint256 actual = wPokt.balanceOf(alice);
        assertEq(expected, actual);
        expected = oldLimit - 100 ether;
        actual = mintController.currentMintLimit();
        assertEq(expected, actual);
    }

    function testMintWrappedPocketLimitFail() public {
        setCopperAddress();
        uint256 mintLimit = mintController.currentMintLimit();
        uint256 amountOverLimit = mintLimit + 1 ether;
        vm.startPrank(copperAddress);
        vm.expectRevert(MintController.OverMintLimit.selector);
        mintController.mintWrappedPocket(alice, amountOverLimit, 1);
    }

    function testMintWrappedPocketEvent() public {
        setCopperAddress();
        vm.startPrank(copperAddress);
        vm.expectEmit(true, false, false, false);
        emit CurrentMintLimit(335_000 ether - 100 ether, block.timestamp);
        mintController.mintWrappedPocket(alice, 100 ether, 1);
    }

    function testMintWrappedPocketAuthFail() public {
        setCopperAddress();
        vm.startPrank(DEVADDR);
        vm.expectRevert(MintController.NonCopper.selector);
        mintController.mintWrappedPocket(alice, 100 ether, 1);
    }

    function testBatchMintWrappedPocket() public {
        setCopperAddress();
        vm.startPrank(copperAddress);
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 100 ether;
        uint256[] memory nonces = new uint256[](2);
        nonces[0] = 1;
        nonces[1] = 1;
        mintController.batchMintWrappedPocket(recipients, amounts, nonces);
        uint256 expected = 100 ether;
        uint256 actual = wPokt.balanceOf(alice);
        assertEq(expected, actual);
        actual = wPokt.balanceOf(bob);
        assertEq(expected, actual);
    }

    function testBatchMintWrappedPocketLimit() public {
        setCopperAddress();
        uint256 oldLimit = mintController.currentMintLimit();
        vm.startPrank(copperAddress);
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 100 ether;
        uint256[] memory nonces = new uint256[](2);
        nonces[0] = 1;
        nonces[1] = 1;
        mintController.batchMintWrappedPocket(recipients, amounts, nonces);
        uint256 expected = 100 ether;
        uint256 actual = wPokt.balanceOf(alice);
        assertEq(expected, actual);
        actual = wPokt.balanceOf(bob);
        assertEq(expected, actual);
        expected = oldLimit - 200 ether;
        actual = mintController.currentMintLimit();
        assertEq(expected, actual);
    }

    function testBatchMintWrappedPocketLimitFail() public {
        setCopperAddress();
        uint256 mintLimit = mintController.currentMintLimit();
        uint256 amountOverLimit = mintLimit + 1 ether;
        vm.startPrank(copperAddress);
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = amountOverLimit;
        amounts[1] = 100 ether;
        uint256[] memory nonces = new uint256[](2);
        nonces[0] = 1;
        nonces[1] = 1;
        vm.expectRevert(MintController.OverMintLimit.selector);
        mintController.batchMintWrappedPocket(recipients, amounts, nonces);
    }

    function testBatchMintWrappedPocketLimitFail2() public {
        setCopperAddress();
        uint256 mintLimit = mintController.currentMintLimit();
        uint256 halfLimit = mintLimit / 2;
        vm.startPrank(copperAddress);
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = halfLimit + 10_000 ether;
        amounts[1] = halfLimit + 10_000 ether;
        uint256[] memory nonces = new uint256[](2);
        nonces[0] = 1;
        nonces[1] = 1;
        vm.expectRevert(MintController.OverMintLimit.selector);
        mintController.batchMintWrappedPocket(recipients, amounts, nonces);
    }

    function testBatchMintWrappedPocketEvent() public {
        setCopperAddress();
        vm.startPrank(copperAddress);
        address[] memory recipients = new address[](2);
        recipients[0] = alice;
        recipients[1] = bob;
        uint256[] memory amounts = new uint256[](2);
        amounts[0] = 100 ether;
        amounts[1] = 100 ether;
        uint256[] memory nonces = new uint256[](2);
        nonces[0] = 1;
        nonces[1] = 1;
        vm.expectEmit(true, false, false, false);
        emit CurrentMintLimit(335_000 ether - 200 ether, block.timestamp);
        mintController.batchMintWrappedPocket(recipients, amounts, nonces);
    }

    function testSetMintCooldown() public {
        setCopperAddress();
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
        setCopperAddress();
        vm.startPrank(DEVADDR);
        vm.expectEmit(true, false, false, false);
        emit MintCooldownSet(100_000 ether, 10 ether);
        mintController.setMintCooldown(100_000 ether, 10 ether);
    }

    function testSetMintCooldownFail() public {
        setCopperAddress();
        vm.startPrank(alice);
        vm.expectRevert(MintController.NonAdmin.selector);
        mintController.setMintCooldown(100_000 ether, 10 ether);
    }

    function testFullCooldown() public {
        setCopperAddress();
        vm.startPrank(copperAddress);
        uint256 mintLimit = mintController.currentMintLimit();
        mintController.mintWrappedPocket(alice, mintLimit, 1);
        uint256 expected = 0;
        uint256 actual = mintController.currentMintLimit();
        assertEq(expected, actual);
        vm.warp(block.timestamp + 2 days);
        expected = 335_000 ether;
        actual = mintController.currentMintLimit();
        assertEq(expected, actual);
    }

    function testPartialCooldown() public {
        setCopperAddress();
        vm.startPrank(copperAddress);
        uint256 mintLimit = mintController.currentMintLimit();
        mintController.mintWrappedPocket(alice, mintLimit, 1);
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
        setCopperAddress();
        vm.startPrank(copperAddress);
        uint256 mintLimit = mintController.currentMintLimit();
        mintController.mintWrappedPocket(alice, mintLimit, 1);
        uint256 expected = 0;
        uint256 actual = mintController.currentMintLimit();
        assertEq(expected, actual);
        vm.warp(block.timestamp + 6 hours);
        uint256 mintPerSecond = mintController.mintPerSecond();
        expected = mintPerSecond * 6 hours;
        actual = mintController.currentMintLimit();
        assertEq(expected, actual);
        mintController.mintWrappedPocket(bob, expected, 1);
        actual = wPokt.balanceOf(bob);
        assertEq(expected, actual);
    }

}