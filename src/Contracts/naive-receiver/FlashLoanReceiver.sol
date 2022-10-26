// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

/**
 * @title FlashLoanReceiver
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FlashLoanReceiver {
    using Address for address payable;

    address payable private pool;

    error SenderMustBePool();
    error CannotBorrowThatMuch();

    constructor(address payable poolAddress) {
        pool = poolAddress;
    }

    // Function called by the pool during flash loan
    function receiveEther(uint256 fee) public payable {
        // cannot bypass this
        if (msg.sender != pool) revert SenderMustBePool();
        // attacker can only control msg.value. 
        uint256 amountToBeRepaid = msg.value + fee;

        if (address(this).balance < amountToBeRepaid)
            revert CannotBorrowThatMuch();

        _executeActionDuringFlashLoan();

        // Return funds to pool
        pool.sendValue(amountToBeRepaid);
    }

    // Internal function where the funds received are used
    function _executeActionDuringFlashLoan() internal {
        
    }

    // Allow deposits of ETH
    receive() external payable {}
}
