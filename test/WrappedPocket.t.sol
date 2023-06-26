// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/WrappedPocket.sol";

contract WrappedPocketTest is Test {

    WrappedPocket public wPokt;

    function setUp() public {
        wPokt = new WrappedPocket();
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

}
