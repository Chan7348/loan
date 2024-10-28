// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {BUProxy} from "./proxy/BUProxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IUserAccount} from "./interfaces/IUserAccount.sol";
import {IUserAccountFactory} from "./interfaces/IUserAccountFactory.sol";

contract UserAccountFactory is
    IUserAccountFactory,
    Initializable,
    AccessControlUpgradeable,
    ReentrancyGuardUpgradeable
{
    mapping(address user => address account) public UserToAccount;
    mapping(address account => address user) public AccountToUser;

    address public beacon;
    address public baseToken;
    address public quoteToken;
    address public aQuoteToken;
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
        address _aQuoteToken,
        address _uniPool,
        address _aavePool
    ) external initializer {
        _grantRole(DEFAULT_ADMIN_ROLE, _admin);
        __ReentrancyGuard_init();
        beacon = _beacon;
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        aQuoteToken = _aQuoteToken;
        uniPool = _uniPool;
        aavePool = _aavePool;
    }

    function register() external {
        address user = msg.sender;
        require(UserToAccount[user] == address(0), UserAccountExists(user, UserToAccount[user]));

        address account = address(new BUProxy(beacon, abi.encodeCall(IUserAccount.initialize, (address(this)))));
        UserToAccount[user] = account;
        AccountToUser[account] = user;
        emit Register(user);
    }
}
