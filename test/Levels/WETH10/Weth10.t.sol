// SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {Utilities} from "../../utils/Utilities.sol";
import "forge-std/Test.sol";

import {WETH10} from "../../../src/Contracts/WETH10/WETH10.sol";
import {Exploit} from "../../../src/Contracts/WETH10/Exploit.sol";
import {Exploit2} from "../../../src/Contracts/WETH10/Exploit2.sol";

contract Weth10Test is Test {
    Utilities internal utils;

    WETH10 public weth;
    Exploit public exploit;
    Exploit2 public exploit2;
    address owner;
    address bob;

    function setUp() public {
        weth = new WETH10();

        utils = new Utilities();
        address payable[] memory users = utils.createUsers(1);
        bob = users[0];

        vm.label(bob, "Bob");
        vm.deal(address(weth), 10 ether);
        vm.deal(address(bob), 1 ether);
    }

    function testHack() public {
        assertEq(
            address(weth).balance,
            10 ether,
            "weth contract should have 10 ether"
        );

        vm.startPrank(bob);
        exploit2 = new Exploit2(payable(weth));
        exploit = new Exploit(payable(weth), address(exploit2));
        exploit.attack{value: 1 ether}();
        exploit.withdrawAll();
        // hack time!

        vm.stopPrank();
        assertEq(address(weth).balance, 0, "empty weth contract");
        assertEq(bob.balance, 11 ether, "player should end with 11 ether");
    }
}
