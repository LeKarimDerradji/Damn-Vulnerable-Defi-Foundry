pragma solidity 0.8.12;
import "forge-std/Test.sol";

contract FallBackHandler {
    fallback() external {
        console.log("LOGGING FALLBACK FUNCTION");
    }
}
