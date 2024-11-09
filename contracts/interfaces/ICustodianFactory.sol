// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface ICustodianFactory {
    function UserToAccount(address user) external view returns (address account);
    function AccountToUser(address Account) external view returns (address user);
    function beacon() external view returns (address);

    function baseToken() external view returns (address);
    function aaveBaseToken() external view returns (address);
    function aaveDebtBaseToken() external view returns (address);

    function quoteToken() external view returns (address);
    function aaveQuoteToken() external view returns (address);
    function aaveDebtQuoteToken() external view returns (address);

    function uniPool() external view returns (address);
    function aavePool() external view returns (address);

    function initialize(
        address _admin,
        address _beacon,
        address _baseToken,
        address _quoteToken,
        address _uniPool,
        address _aavePool
    ) external;

    function register() external;
}
