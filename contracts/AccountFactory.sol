// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {BUProxy} from "./proxy/BUProxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IAccount} from "./interfaces/IAccount.sol";

contract AccountFactory is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {

    mapping(address user => address account) public accounts;

    address public beacon;
    address public baseToken;
    address public quoteToken;
    address public uniPool;
    address public aavePool;

    error AccountExists(address user, address account);

    event Register(address indexed user);

    constructor() {
        _disableInitializers();
    }

    function initialize(address _admin, address _beacon, address _baseToken, address _quoteToken) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        __ReentrancyGuard_init();
        beacon = _beacon;
        baseToken = _baseToken;
        quoteToken = _quoteToken;
    }

    function register() external {
        address user = msg.sender;
        require(accounts[user] == address(0), AccountExists(user, accounts[user]));
        bytes memory data = abi.encodeCall(IAccount.initialize, (address(this), user, baseToken, quoteToken, uniPool, aavePool));
        accounts[user] = address(new BUProxy(beacon, data));

        emit Register(user);
    }
}