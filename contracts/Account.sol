// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IAccount} from "./interfaces/IAccount.sol";

contract Account is IAccount, Initializable, OwnableUpgradeable {
    address public factory;
    address public user;
    address public baseToken;
    address public quoteToken;
    address public uniPool;
    address public aavePool;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _factory, address _user, address _baseToken, address _quoteToken, address _uniPool, address _aavePool) external initializer() {
        factory = _factory;
        user = _user;
        baseToken = _baseToken;
        quoteToken = _quoteToken;
        uniPool = _uniPool;
        aavePool = _aavePool;
        __Ownable_init(_user);
    }

    function deposit() external onlyOwner() {

    }
}