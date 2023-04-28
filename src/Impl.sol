//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface Impl {
    function start() external returns (uint256,uint256);

    function end(address refer) external payable;
}
