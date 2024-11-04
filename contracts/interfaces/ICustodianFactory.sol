// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface ICustodianFactory {
    function UserToAccount(address user) external returns (address account);
    function AccountToUser(address Account) external returns (address user);
    function beacon() external returns (address);

    function baseToken() external returns (address);
    function aBaseToken() external returns (address);

    function quoteToken() external returns (address);
    function aQuoteToken() external returns (address);

    function uniPool() external returns (address);
    function aavePool() external returns (address);

    function initialize(
        address _admin,
        address _beacon,
        address _baseToken,
        address _quoteToken,
        address _aQuoteToken,
        address _uniPool,
        address _aavePool
    ) external;

    function register() external;
}
