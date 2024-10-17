// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {TransparentUpgradeableProxy} from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

contract TUProxy is TransparentUpgradeableProxy {
    constructor(address _logic, address _proxyAdmin, bytes memory _data) payable TransparentUpgradeableProxy(_logic, _proxyAdmin, _data) {}
}