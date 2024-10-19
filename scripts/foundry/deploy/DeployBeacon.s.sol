// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "forge-std/Script.sol";
import "contracts/IKUN.sol";

contract DeployBeacon is Script {

    function run() external {
        uint deployPrivateKey = ;
        address owner = ;
        console.log(owner.balance);
        vm.startBroadcast(deployPrivateKey);
        IKUN ikun = new IKUN();
        vm.stopBroadcast();
    }
}