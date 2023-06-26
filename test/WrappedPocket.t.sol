// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/WrappedPocket.sol";

contract WrappedPocketTest is Test {

    function setUp() public {
        WrappedPocket wPokt = new WrappedPocket();
    }

}
