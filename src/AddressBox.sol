//SPDX-License-Identifier: Unlicense
pragma solidity 0.8.17;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IProxy {
    function delegatecall(address impl, bytes calldata data) external payable;
}

interface Impl {
    function start() external;

    function end(address refer) external payable;

    function useFee() external view returns (uint256);

    function runValue() external view returns (uint256);
}

contract AddressBox is ERC721, Ownable {
    struct Token {
        uint128 start;
        uint128 end;
    }

    uint256 public totalProxy;

    uint256 public totalToken;

    string public baseURI = "https://xenbox.store/api/token/";

    mapping(uint256 => Token) public tokenMap;

    mapping(address => bool) public implMap;

    address immutable _thisAddress = address(this);

    constructor() ERC721("xenbox.store", "xenbox") {}

    /* ================ UTIL FUNCTIONS ================ */

    function _baseURI() internal view override returns (string memory) {
        return baseURI;
    }

    function _batchCreate(uint256 start, uint256 end) internal {
        bytes memory code = abi.encodePacked(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            _thisAddress,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        for (uint256 i = start; i < end; i++) {
            assembly {
                pop(create2(0, add(code, 32), mload(code), i))
            }
        }
    }

    function _batchCreateAndRun(uint256 start, uint256 end, address impl, address refer, bytes calldata data) internal {
        bytes memory code = abi.encodePacked(
            bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
            _thisAddress,
            bytes15(0x5af43d82803e903d91602b57fd5bf3)
        );
        Impl _impl = Impl(impl);
        _impl.start();
        uint256 runValue = _impl.runValue();
        for (uint256 i = start; i < end; i++) {
            IProxy proxy;
            assembly {
                proxy := create2(0, add(code, 32), mload(code), i)
            }
            proxy.delegatecall{value: runValue}(impl, data);
        }
        _impl.end{value: _impl.useFee()}(refer);
    }

    function _batchRun(uint256 start, uint256 end, address impl, address refer, bytes calldata data) internal {
        bytes32 _codehash = keccak256(
            abi.encodePacked(
                bytes20(0x3D602d80600A3D3981F3363d3d373d3D3D363d73),
                _thisAddress,
                bytes15(0x5af43d82803e903d91602b57fd5bf3)
            )
        );
        Impl _impl = Impl(impl);
        _impl.start();
        uint256 runValue = _impl.runValue();
        for (uint256 i = start; i < end; i++) {
            IProxy(address(uint160(uint256(keccak256(abi.encodePacked(bytes1(0xff), _thisAddress, i, _codehash))))))
                .delegatecall{value: runValue}(impl, data);
        }
        _impl.end{value: _impl.useFee()}(refer);
    }

    function delegatecall(address impl, bytes calldata data) external payable {
        require(msg.sender == _thisAddress);
        impl.delegatecall(data);
    }

    /* ================ VIEW FUNCTIONS ================ */

    /* ================ TRAN FUNCTIONS ================ */

    function mint(uint256 amount, address impl, address refer, bytes calldata data) external payable {
        require(msg.sender == tx.origin, "not user");
        require(amount == 100 || amount == 50 || amount == 20 || amount == 10, "error amount");
        uint256 end = totalProxy + amount;
        if (impl != address(0)) {
            require(implMap[impl], "not allow impl");
            _batchCreateAndRun(totalProxy, end, impl, refer, data);
        } else {
            _batchCreate(totalProxy, end);
        }
        _mint(msg.sender, totalToken);
        tokenMap[totalToken] = Token({start: uint128(totalProxy), end: uint128(end)});
        totalProxy += amount;
        totalToken++;
    }

    function run(uint256 tokenId, address impl, address refer, bytes calldata data) external payable {
        require(msg.sender == tx.origin, "not user");
        require(ownerOf(tokenId) == msg.sender, "not owner");
        require(implMap[impl], "not allow impl");
        _batchRun(tokenMap[tokenId].start, tokenMap[tokenId].end, impl, refer, data);
    }

    /* ================ ADMIN FUNCTIONS ================ */

    function setBaseURI(string memory __baseURI) external onlyOwner {
        baseURI = __baseURI;
    }

    function addImpl(address impl) external onlyOwner {
        implMap[impl] = true;
    }

    function removeImpl(address impl) external onlyOwner {
        implMap[impl] = false;
    }
}
