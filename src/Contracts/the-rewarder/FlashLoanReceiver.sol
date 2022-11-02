// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

interface IFlashLoanReceiver {
    function receiveFlashLoan(uint256 amount) external;
    error IsNotFlashLoanerPool();
}

contract FlashLoanReceiver {
    address private _attacker;
    address private _flashLoanerPool;

    error IsNotFlashLoanerPool();
    constructor(address attacker, address flashLoanerPool) {
        _attacker = attacker;
        _flashLoanerPool = flashLoanerPool;
    }

    function receiveFlashLoan(uint256 amount) external {
        if(msg.sender != _flashLoanerPool) revert IsNotFlashLoanerPool();
        // trade LP tokens for AccToken and RewardToken
    }
}
