pragma solidity 0.8.12;

import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {WalletRegistry} from "./WalletRegistry.sol";

// Your contract
contract MyContract {
    // Address of the Gnosis Safe master copy contract
    address immutable gnosisSafeMasterCopy;

    // Address of the Gnosis Safe proxy factory contract
    address immutable gnosisSafeProxyFactory;

    WalletRegistry immutable walletRegistry;

    constructor(
        address gnosisSafeMasterCopy_,
        address gnosisSafeProxyFactory_,
        WalletRegistry walletRegistry_
    ) {
        gnosisSafeMasterCopy = gnosisSafeMasterCopy_;
        gnosisSafeProxyFactory = gnosisSafeProxyFactory_;
        walletRegistry = walletRegistry_;
    }

    function createGnosisSafeWallet(
        address[] memory owners,
        uint256 threshold
    ) public {
        // Encode the data for the GnosisSafe "setup" function call
        bytes memory initializer = abi.encodeWithSignature(
            "setup(address[],uint256)",
            owners,
            threshold
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
