// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {BeaconProxy} from "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";

contract BUProxy is BeaconProxy {
    constructor(address _beacon, bytes memory _data) payable BeaconProxy(_beacon, _data) {}
}