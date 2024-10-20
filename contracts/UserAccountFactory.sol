// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {BUProxy} from "./proxy/BUProxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IUserAccount} from "./interfaces/IUserAccount.sol";

contract UserAccountFactory is Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    mapping(address user => address UserAccount) public UserAccounts;

    address public beacon;
    address public baseToken;
    address public quoteToken;
    address public uniPool;
    address public aavePool;

    error UserAccountExists(address user, address UserAccount);

    event Register(address indexed user);

    constructor() {
        _disableInitializers();
    }

    function initialize(
        address _admin,
        address _beacon,
        address _baseToken,
        address _quoteToken,
        address _uniPool,
        address _aavePool
    ) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        __ReentrancyGuard_init();
        beacon = _beacon;
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        uniPool = _uniPool;
        aavePool = _aavePool;
    }

    function register() external {
        address user = msg.sender;
        require(UserAccounts[user] == address(0), UserAccountExists(user, UserAccounts[user]));

        UserAccounts[user] = address(
            new BUProxy(
                beacon,
                abi.encodeCall(IUserAccount.initialize, (address(this), user, baseToken, quoteToken, uniPool, aavePool))
            )
        );

        emit Register(user);
    }
}
