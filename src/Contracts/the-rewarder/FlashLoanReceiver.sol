// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {RewardToken} from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {AccountingToken} from "./AccountingToken.sol";

interface IFlashLoanReceiver {
    function receiveFlashLoan(uint256 amount) external;

    error IsNotFlashLoanerPool();
}

interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;

    function withdraw(uint256 amountToWithdraw) external;

    function distributeRewards() external returns (uint256);
}

contract FlashLoanReceiver {
    address private _attacker;
    address private _flashLoanerPool;
    address private _dvt;
    address private _rewardToken;
    address private _accToken;

    error IsNotFlashLoanerPool();

    constructor(
        address attacker,
        address flashLoanerPool,
        address dvtAddress,
        address rewardTokenAddress,
        address accTokenAddress
    ) {
        _attacker = attacker;
        _flashLoanerPool = flashLoanerPool;
        _dvt = dvtAddress;
        _rewardToken = rewardTokenAddress;
        _accToken = accTokenAddress;
    }

    function receiveFlashLoan(uint256 amount) external {
        if (msg.sender != _flashLoanerPool) revert IsNotFlashLoanerPool();
        // trade LP tokens for AccToken and RewardToken
    }
}
