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

    event FeeSet(bool indexed flag, uint256 indexed newFeeBasis, address indexed feeCollector);
    event FeeCollected(address indexed feeCollector, uint256 indexed amount);
    event BurnAndBridge(uint256 indexed amount, address indexed poktAddress, address indexed from);

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

    function testStartingGetUserNonce() public {
        uint256 expected = 0;
        uint256 actual = wPokt.getUserNonce(alice);
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

    function testMinterRole() public {
        bool expected = true;
        bool actual = wPokt.hasRole(wPokt.MINTER_ROLE(), MINTER);
        assertEq(actual, expected);
    }

    function testPauserRole() public {
        bool expected = true;
        bool actual = wPokt.hasRole(wPokt.PAUSER_ROLE(), PAUSER);
        assertEq(actual, expected);
    }

    function testSetFeeCollector() public {
        vm.startPrank(DEVADDR);
        wPokt.setFee(false, 0, FEE_COLLECTOR);
        vm.stopPrank();
        address expected = FEE_COLLECTOR;
        address actual = wPokt.feeCollector();
        assertEq(actual, expected);
    }

    function testSetFeeBasis() public {
        vm.startPrank(DEVADDR);
        wPokt.setFee(false, 100, FEE_COLLECTOR);
        vm.stopPrank();
        uint256 expected = 100;
        uint256 actual = wPokt.feeBasis();
        assertEq(actual, expected);
    }

    function testSetFeeFlag() public {
        vm.startPrank(DEVADDR);
        wPokt.setFee(true, 100, FEE_COLLECTOR);
        vm.stopPrank();
        bool expected = true;
        bool actual = wPokt.feeFlag();
        assertEq(actual, expected);
    }

    function testReversingSetFeeFalse() public {
        vm.startPrank(DEVADDR);
        wPokt.setFee(true, 100, FEE_COLLECTOR);
        wPokt.setFee(false, 0, FEE_COLLECTOR);
        vm.stopPrank();
        bool expectedFlag = false;
        bool actualFlag = wPokt.feeFlag();
        assertEq(actualFlag, expectedFlag);
        uint256 expectedBasis = 0;
        uint256 actualBasis = wPokt.feeBasis();
        assertEq(actualBasis, expectedBasis);
    }

    function testSetFeeCollectorZeroAddressFail() public {
        vm.startPrank(DEVADDR);
        vm.expectRevert(WrappedPocket.FeeCollectorZero.selector);
        wPokt.setFee(true, 0, address(0));
        vm.stopPrank();
    }

    function testSetFeeBasisOverMaxBasisFail() public {
        vm.startPrank(DEVADDR);
        vm.expectRevert(WrappedPocket.MaxBasis.selector);
        wPokt.setFee(true, 301, FEE_COLLECTOR);
        vm.stopPrank();
    }

    function testSetFeeEvent() public {
        vm.expectEmit(true, true, true, false);
        emit FeeSet(true, 100, FEE_COLLECTOR);
        vm.startPrank(DEVADDR);
        wPokt.setFee(true, 100, FEE_COLLECTOR);
        vm.stopPrank();
    }

    function testPause() public {
        vm.startPrank(PAUSER);
        wPokt.pause();
        vm.stopPrank();
        bool expected = true;
        bool actual = wPokt.paused();
        assertEq(actual, expected);
    }

    function testUnpause() public {
        vm.startPrank(PAUSER);
        wPokt.pause();
        wPokt.unpause();
        vm.stopPrank();
        bool expected = false;
        bool actual = wPokt.paused();
        assertEq(actual, expected);
    }

}
