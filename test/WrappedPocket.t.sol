// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/WrappedPocket.sol";

contract WrappedPocketTest is Test {

    WrappedPocket public wPokt;

    address internal constant alice = address(0xAAAA);
    address internal constant bob = address(0xBBBB);
    address internal constant DEVADDR = address(0xBEEF);
    address internal constant FEE_COLLECTOR = address(0xFEEE);
    address internal constant MINTER = address(0x1337);
    address internal constant PAUSER = address(0x1111);

    function setUp() public {
        vm.startPrank(DEVADDR);
        wPokt = new WrappedPocket();
        wPokt.grantRole(wPokt.MINTER_ROLE(), MINTER);
        wPokt.grantRole(wPokt.PAUSER_ROLE(), PAUSER);
        vm.stopPrank();
    }

    function testTokenName() public {
        string memory expected = "Wrapped Pocket";
        string memory actual = wPokt.name();
        assertEq(actual, expected);
    }

    function testTokenSymbol() public {
        string memory expected = "wPOKT";
        string memory actual = wPokt.symbol();
        assertEq(actual, expected);
    }

    function testTokenDecimals() public {
        uint256 expected = 6;
        uint256 actual = wPokt.decimals();
        assertEq(actual, expected);
    }

    function testTokenDecimalsNot18() public {
        uint256 expected = 18;
        uint256 actual = wPokt.decimals();
        assertNotEq(actual, expected);
    }

    function testStartingTokenTotalSupply() public {
        uint256 expected = 0;
        uint256 actual = wPokt.totalSupply();
        assertEq(actual, expected);
    }

    function testStartingFeeFlag() public {
        bool expected = false;
        bool actual = wPokt.feeFlag();
        assertEq(actual, expected);
    }

    function testStartingBasisPoints() public {
        uint256 expected = 10000;
        uint256 actual = wPokt.BASIS_POINTS();
        assertEq(actual, expected);
    }

    function testStartingMaxBasis() public {
        uint256 expected = 300;
        uint256 actual = wPokt.MAX_FEE_BASIS();
        assertEq(actual, expected);
    }

    function testStartingFeeCollector() public {
        address expected = address(0);
        address actual = wPokt.feeCollector();
        assertEq(actual, expected);
    }

    function testStartingFeeBasis() public {
        uint256 expected = 0;
        uint256 actual = wPokt.feeBasis();
        assertEq(actual, expected);
    }

    function testDeployerIsAdmin() public {
        bool expected = true;
        bool actual = wPokt.hasRole(wPokt.DEFAULT_ADMIN_ROLE(), DEVADDR);
        assertEq(actual, expected);
    }

}
