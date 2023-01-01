pragma solidity 0.8.12;

import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";

// Your contract
contract MyContract {
    // Address of the Gnosis Safe master copy contract
    address immutable gnosisSafeMasterCopy;

    // Address of the Gnosis Safe proxy factory contract
    address immutable gnosisSafeProxyFactory;

    constructor(
        address gnosisSafeMasterCopy_,
        address gnosisSafeProxyFactory_
    ) {
        gnosisSafeMasterCopy = gnosisSafeMasterCopy_;
        gnosisSafeProxyFactory = gnosisSafeProxyFactory_;
    }

    function createGnosisSafeWallet() public {
        // Generate a unique saltNonce value
        uint256 saltNonce = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        );
        // Call the createProxy function of the GnosisSafeProxyFactory contract
        GnosisSafeProxy proxy = GnosisSafeProxyFactory(gnosisSafeProxyFactory)
            .createProxy(
                gnosisSafeMasterCopy,
                abi.encodeWithSelector(
                    GnosisSafe.setup.selector,
                    1,
                    [msg.sender]
                )
            );
    }
}
