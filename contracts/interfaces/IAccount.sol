// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface IAccount {
    function initialize(address _factory, address _user, address _baseToken, address _quoteToken, address _uniPool, address _aavePool) external;
}
