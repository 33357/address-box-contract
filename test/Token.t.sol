// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";

contract TokenTest is Test {
    address immutable _thisAddress = address(this);

    function setUp() public {}

    function test1() public {
         for (uint256 i = 0; i < 100; i++) {
            address x = address(this);
        }
        
    }

    function test2() public {
        for (uint256 i = 0; i < 100; i++) {
            address x = _thisAddress;
        }
    }
}
