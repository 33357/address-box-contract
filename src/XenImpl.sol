//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Impl.sol";

interface IXen {
    function claimRank(uint256 term) external;

    function claimMintRewardAndShare(address other, uint256 pct) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract XenImpl is Ownable, Impl {
    uint256 public totalFee;

    uint256 public fee = 500;

    uint256 public referFee = 100;

    mapping(address => uint256) public rewardMap;

    address public constant xenAddress = 0x2AB0e9e4eE70FFf1fB9D67031E44F6410170d00e;

    address immutable _thisAddress = address(this);

    uint256 public runValue;

    uint256 _beforeBalance;

    constructor() {}

    /* ================ UTIL FUNCTIONS ================ */

    function start(address sender, uint256 amount, address refer) external returns (uint256, uint256) {
        _beforeBalance = IXen(xenAddress).balanceOf(address(this));
        return (runValue, useFee(sender, amount, refer));
    }

    function useFee(address, uint256, address) public pure returns (uint256) {
        return 0;
    }

    function end(address sender, uint256, address refer) external payable {
        IXen xen = IXen(xenAddress);
        uint256 getBalance = xen.balanceOf(address(this)) - _beforeBalance;
        if (getBalance > 0) {
            uint256 getAmount = (getBalance * (10000 - fee)) / 10000;
            uint256 rewardAmount;
            if (refer != sender) {
                rewardAmount = (getBalance * referFee) / 10000;
                rewardMap[refer] += rewardAmount;
            }
            totalFee += getBalance - getAmount - rewardAmount;
            xen.transfer(sender, getAmount);
        }
    }

    function rankAndReward(uint256 term) external {
        IXen xen = IXen(xenAddress);
        xen.claimMintRewardAndShare(_thisAddress, 100);
        xen.claimRank(term);
    }

    function rank(uint256 term) external {
        IXen(xenAddress).claimRank(term);
    }

    /* ================ VIEW FUNCTIONS ================ */

    /* ================ TRAN FUNCTIONS ================ */

    function getReward() external {
        uint256 rewardAmount = rewardMap[msg.sender];
        rewardMap[msg.sender] = 0;
        IXen(xenAddress).transfer(msg.sender, rewardAmount);
    }

    /* ================ ADMIN FUNCTIONS ================ */

    function getFee(address to) external onlyOwner {
        IXen(xenAddress).transfer(to, totalFee);
        totalFee = 0;
    }

    function setFee(uint256 _fee, uint256 _referFee) external onlyOwner {
        fee = _fee;
        referFee = _referFee;
    }
}
