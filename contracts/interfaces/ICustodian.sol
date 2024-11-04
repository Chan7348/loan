// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

interface ICustodian {
    function initialize(address _factory) external;
    function factory() external returns (address);
    function baseReserve() external returns (uint256);
    function quoteReserve() external returns (uint256);
    function deposit(bool isBase, uint256 amount) external;
    function withdraw(bool isBase, uint256 amount, bool isFullyWithdraw) external;
    function openLong(uint256 leverage) external;
    function openShort(uint256 leverage) external;
    function closeLong() external;
    function closeShort() external;
}
