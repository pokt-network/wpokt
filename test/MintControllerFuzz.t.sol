// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "../src/WrappedPocket.sol";
import "../src/MintController.sol";

contract MintControllerFuzzTest is Test {

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

    function deriveCooldown() public view returns (uint256) {
        uint256 timeSinceLastMint = block.timestamp - mintController.lastMint();
        uint256 mintableFromCooldown = timeSinceLastMint * mintController.mintPerSecond();
        return mintableFromCooldown;
    }

//    INVARIANTS:
//
//    - Should never mint more than current limit
//    - Current limit should never be more than max limit
//    - Current limit should never be more than past limit + sec since last mint * mint per second

    function testFuzzCurrentLimit(uint256 amount) public {
        setCopperAddress();
        vm.startPrank(copperAddress);
        if ( amount > mintController.currentMintLimit() ) {
            vm.expectRevert(MintController.OverMintLimit.selector);
        }
        mintController.mintWrappedPocket(alice, amount, 1);
    }

    function testFuzzCurrentLimitNeverAboveMax(uint256 amount, uint256 time) public {
        time = bound(time, 1, 604_800);
        amount = bound(amount, 1 ether, mintController.maxMintLimit());
        setCopperAddress();
        vm.startPrank(copperAddress);
        uint256 maxLimit = mintController.maxMintLimit();
        require(maxLimit >= mintController.currentMintLimit(), "maxLimit must be greater than current limit");
        mintController.mintWrappedPocket(alice, amount, 1);
        require(maxLimit >= mintController.currentMintLimit(), "maxLimit must be greater than current limit");
        time = time + block.timestamp;
        vm.warp(time);
        require(maxLimit >= mintController.currentMintLimit(), "maxLimit must be greater than current limit");
    }

    function testFuzzCooldownAndLimit(uint256 amount, uint256 time) public {
        time = bound(time, 1, 604_800);
        amount = bound(amount, 1 ether, mintController.maxMintLimit());
        setCopperAddress();
        vm.startPrank(copperAddress);
        mintController.mintWrappedPocket(alice, amount, 1);
        uint256 lastMint = mintController.lastMintLimit();
        vm.warp(time);
        uint256 cooldown = deriveCooldown();
        require(mintController.currentMintLimit() <= cooldown + lastMint, "current limit must be less than cooldown + last mint");
    }

}

