// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {UpgradeableBeacon} from "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";

contract Beacon is UpgradeableBeacon {
    constructor(address _impl, address owner) payable UpgradeableBeacon(_impl, owner) {}
}