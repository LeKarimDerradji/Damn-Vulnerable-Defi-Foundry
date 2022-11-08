// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IPuppetPool {
    function borrow(uint256) external;
}

contract HighlyProfitableStrategy {
    address private _attacker;
    address private _puppetPool;
    address private _uniswapPool;

    error OnlyAttacker();

    constructor(address puppetPool, address uniswapPool) {
        _attacker = msg.sender;
        _puppetPool = puppetPool;
        _uniswapPool = uniswapPool;
    }

    function attack(uint256 amount) external {
        if (msg.sender != _attacker) revert OnlyAttacker();
        IPuppetPool(_puppetPool).borrow(amount);
    }
}
