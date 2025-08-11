// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/BuggySafe.sol";

contract BuggySafeTest is Test {
    BuggySafe public buggySafe;

    address public owner = address(0x1);

    function setUp() public {
        vm.deal(owner, 200 ether);
        vm.startPrank(owner);
        buggySafe = new BuggySafe();
        vm.stopPrank();
    }

    // Test 1: Demonstrate that funds get stuck after withdrawal
    function testFundsGetStuckAfterDeposit() public {
        vm.startPrank(owner);

        // Owner deposits 2 ETH
        buggySafe.deposit{value: 2 ether}();

        // Check initial state
        assertEq(buggySafe.getBalance(), 2 ether);
        assertEq(buggySafe.getContractBalance(), 2 ether);

        // Owner withdraws (this should work)
        vm.expectRevert("Not enough funds to withdraw");
        buggySafe.withdraw();

        assertEq(buggySafe.getBalance(), 2 ether);
        assertEq(buggySafe.getContractBalance(), 2 ether);
        vm.stopPrank();
    }
}
