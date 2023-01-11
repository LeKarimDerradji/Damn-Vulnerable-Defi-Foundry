pragma solidity 0.8.12;

import {ModuleManager} from "gnosis/base/ModuleManager.sol";
import {Enum} from "gnosis/common/Enum.sol";
import {GnosisSafe} from "gnosis/GnosisSafe.sol";

contract ControllerModule is ModuleManager {

    GnosisSafe internal proxy;
    
    function setup(address payable proxy_) public {
        proxy = GnosisSafe(proxy_);
    }
    
    // Allows anyone to execute a call from the controlled wallet
    function executeCall(address to, uint256 value, bytes memory data) public {
        // `manager` represents the wallet under control
        require(
            proxy.execTransactionFromModule(to, value, data, Enum.Operation.Call)
        );
    }
    
    // Allows anyone to become the wallet's owner
    function becomeOwner(address currentOwner) external {
        executeCall(
            address(proxy),
            0,
            abi.encodeWithSignature(
                "swapOwner(address,address,address)",
                address(0x1),
                currentOwner,
                msg.sender
            )
        );
    }
}