//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

interface Impl {
    function start(address sender,uint256 amount, address refer) external returns (uint256 runValue, uint256 usefee);

    function end(address sender,uint256 amount, address refer) external payable;

    function useFee(address sender,uint256 amount, address refer) external view returns (uint256);
}
