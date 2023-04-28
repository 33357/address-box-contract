//SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

interface IXEN {
    struct MintInfo {
        address user;
        uint256 term;
        uint256 maturityTs;
        uint256 rank;
        uint256 amplifier;
        uint256 eaaRate;
    }

    function globalRank() external view returns (uint256);

    function SECONDS_IN_DAY() external view returns (uint256);

    function WITHDRAWAL_WINDOW_DAYS() external view returns (uint256);

    function MAX_PENALTY_PCT() external view returns (uint256);

    function getGrossReward(
        uint256 rankDelta,
        uint256 amplifier,
        uint256 term,
        uint256 eaa
    ) external pure returns (uint256);

    function userMints(address user) external view returns (MintInfo memory);

    function getCurrentAMP() external view returns (uint256);

    function getCurrentEAAR() external view returns (uint256);
}

contract XenHelper {
    IXEN xen = IXEN(0x06450dEe7FD2Fb8E39061434BAbCFC05599a6Fb8);

    /* ================ UTIL FUNCTIONS ================ */

    function _penalty(uint256 secsLate) public view returns (uint256) {
        uint256 daysLate = secsLate / xen.SECONDS_IN_DAY();
        if (daysLate > xen.WITHDRAWAL_WINDOW_DAYS() - 1) return xen.MAX_PENALTY_PCT();
        uint256 penalty = (uint256(1) << (daysLate + 3)) / xen.WITHDRAWAL_WINDOW_DAYS() - 1;
        return _min(penalty, xen.MAX_PENALTY_PCT());
    }

    function _min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return b;
        return a;
    }

    function _max(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a > b) return a;
        return b;
    }

    /* ================ VIEW FUNCTIONS ================ */

    function getOwnedTokenIdList(
        address target,
        address owner,
        uint256 start,
        uint256 end
    ) external view returns (uint256[] memory tokenIdList) {
        require(start < end, "XenBoxHelper: end must over start");
        IERC721 erc721 = IERC721(target);
        tokenIdList = new uint256[](end - start);
        uint256 index;
        for (uint256 tokenId = start; tokenId < end; tokenId++) {
            if (erc721.ownerOf(tokenId) == owner) {
                tokenIdList[index] = tokenId;
                index++;
            }
        }
        assembly {
            mstore(tokenIdList, index)
        }
    }

    function calculateMintReward(address user) external view returns (uint256) {
        IXEN.MintInfo memory info = xen.userMints(user);
        uint256 secsLate = block.timestamp > info.maturityTs ? block.timestamp - info.maturityTs : 0;
        uint256 penalty = _penalty(secsLate);
        uint256 rankDelta = _max(xen.globalRank() - info.rank, 2);
        uint256 EAA = (1_000 + info.eaaRate);
        uint256 reward = xen.getGrossReward(rankDelta, info.amplifier, info.term, EAA);
        return ((reward * (100 - penalty)) / 100) * 1 ether;
    }

    function calculateMintRewardNew(uint256 addRank, uint256 term) external view returns (uint256) {
        uint256 rankDelta = _max(addRank, 2);
        uint256 EAA = (1_000 + xen.getCurrentEAAR());
        uint256 reward = xen.getGrossReward(rankDelta, xen.getCurrentAMP(), term, EAA);
        return reward * 1 ether;
    }

    function getCreateAddress(address sender, uint256 nonce) external pure returns (address) {
        bytes memory data;
        if (nonce == 0x00) data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, bytes1(0x80));
        else if (nonce <= 0x7f) data = abi.encodePacked(bytes1(0xd6), bytes1(0x94), sender, uint8(nonce));
        else if (nonce <= 0xff) data = abi.encodePacked(bytes1(0xd7), bytes1(0x94), sender, bytes1(0x81), uint8(nonce));
        else if (nonce <= 0xffff)
            data = abi.encodePacked(bytes1(0xd8), bytes1(0x94), sender, bytes1(0x82), uint16(nonce));
        else if (nonce <= 0xffffff)
            data = abi.encodePacked(bytes1(0xd9), bytes1(0x94), sender, bytes1(0x83), uint24(nonce));
        else data = abi.encodePacked(bytes1(0xda), bytes1(0x94), sender, bytes1(0x84), uint32(nonce));
        return address(uint160(uint256(keccak256(data))));
    }

    /* ================ TRAN FUNCTIONS ================ */

    /* ================ ADMIN FUNCTIONS ================ */
}
