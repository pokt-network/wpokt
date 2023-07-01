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

}