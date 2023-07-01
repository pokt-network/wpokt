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
    address internal constant bobPocket = address(0xB0BB);
    address internal constant DEVADDR = address(0xBEEF);
    address internal constant FEE_COLLECTOR = address(0xFEEE);
    address internal constant MINTER = address(0x1337);
    address internal constant PAUSER = address(0x1111);

    function setUp() public {
        vm.startPrank(DEVADDR);
        wPokt = new WrappedPocket();
        wPokt.grantRole(wPokt.MINTER_ROLE(), MINTER);
        wPokt.grantRole(wPokt.PAUSER_ROLE(), PAUSER);
        mintController = new MintController(address(wPokt));
    }

    function testWPOKTSet() public {
        address expected = address(wPokt);
        address actual = address(mintController.wPokt());
        assertEq(expected, actual);
    }



}