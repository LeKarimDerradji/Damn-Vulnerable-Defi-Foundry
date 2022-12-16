// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {IERC721Receiver} from "openzeppelin-contracts/token/ERC721/IERC721Receiver.sol";
import {ReentrancyGuard} from "openzeppelin-contracts/security/ReentrancyGuard.sol";

contract Attacker is IERC721Receiver, ReentrancyGuard {
    address private immutable _buyer;

    constructor(address buyer_, address _nft) payable {
        _buyer = buyer_;
        nft = IERC721(_nft);
        IERC721(_nft).setApprovalForAll(msg.sender, true);
    }

    // Read https://eips.ethereum.org/EIPS/eip-721 for more info on this function
    function onERC721Received(
        address,
        address,
        uint256 _tokenId,
        bytes memory
    ) external override nonReentrant returns (bytes4) {
        require(msg.sender == address(nft));
        // This require might be the way to exploit it.
        require(tx.origin == partner);
        require(_tokenId >= 0 && _tokenId <= 5);
        require(nft.ownerOf(_tokenId) == address(this));

        received++;
        if (received == 6) {
            payable(partner).sendValue(JOB_PAYOUT);
        }

        return IERC721Receiver.onERC721Received.selector;
    }
}
