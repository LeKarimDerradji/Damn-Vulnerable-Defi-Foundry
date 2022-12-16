// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC721Receiver} from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";
import {IERC721} from "openzeppelin-contracts/token/ERC721/IERC721.sol";

contract Attacker is IERC721Receiver, ReentrancyGuard {
    address private immutable _buyer;
    address private immutable _attacker;
    IERC721 private immutable _nft;
    uint256 private _received;

    constructor(address buyer_, address nft_) payable {
        _buyer = buyer_;
        _nft = IERC721(nft_);
        IERC721(nft_).setApprovalForAll(msg.sender, true);
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
            for(i =0; i < _received; i++) {
                IERC721(_nft).transfer(address(_buyer), i);
            }
            
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}
