// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {AccessControlUpgradeable} from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {BUProxy} from "./proxy/BUProxy.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import {IPool, DataTypes} from "./interfaces/aave/IPool.sol";
import {ICustodian} from "./interfaces/ICustodian.sol";
import {ICustodianFactory} from "./interfaces/ICustodianFactory.sol";

contract CustodianFactory is ICustodianFactory, Initializable, AccessControlUpgradeable, ReentrancyGuardUpgradeable {
    mapping(address user => address account) public UserToAccount;
    mapping(address account => address user) public AccountToUser;

    address public beacon;

    address public baseToken;
    address public aaveBaseToken;
    address public aaveDebtBaseToken;

    address public quoteToken;
    address public aaveQuoteToken;
    address public aaveDebtQuoteToken;

    address public uniPool;
    address public aavePool;

    error CustodianExists(address user, address Custodian);
    error AaveRegistryError();

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

        (aaveBaseToken, aaveDebtBaseToken) = _parseReserveData(baseToken);
        (aaveQuoteToken, aaveDebtQuoteToken) = _parseReserveData(quoteToken);
    }

    function register() external {
        address user = msg.sender;
        require(UserToAccount[user] == address(0), CustodianExists(user, UserToAccount[user]));

        address account = address(new BUProxy(beacon, abi.encodeCall(ICustodian.initialize, (address(this)))));
        UserToAccount[user] = account;
        AccountToUser[account] = user;
        emit Register(user);
    }

    function _parseReserveData(address token) private view returns (address aaveToken, address aaveDebtToken){
            DataTypes.ReserveDataLegacy memory data = IPool(aavePool).getReserveData(token);
            aaveToken = data.aTokenAddress;
            aaveDebtToken = data.variableDebtTokenAddress;
            require(aaveToken != address(0) && aaveDebtToken != address(0), AaveRegistryError());
    }
}
