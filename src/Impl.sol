//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface Impl {
    function start() external returns (uint256 runValue, uint256 usefee);

    function end(address refer) external payable;
}
