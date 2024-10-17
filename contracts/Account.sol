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

    function withdraw() external onlyOwner() {

    }
    // keep a few base token as margin, then mortgage in quote token, and borrow more base token
    // ex. WETH/USDC pair, long WETH,
    // keep a few WETH as margin,
    // flashswap USDC -> WETH(on Uniswap),
    // use all WETH as margin to borrow USDC(on aave)
    // repay minimum USDC to Uniswap
    // Finally, we have more WETH in collateral.
    function openLong() external onlyOwner() {

    }

    // keep a few quote token as margin, then mortage in base token, and borrow more quote token
    // ex. WETH/USDC pair, short WETH,
    // keep a few USDC as margin,
    // flashswap WETH -> USDC(on Uniswap),
    // use all USDC as margin to borrow WETH(on aave)
    // repay minimum WETH to Uniswap
    // Finally, we have more USDC in collateral.
    function openShort() external onlyOwner() {

    }

    function closeLong() external onlyOwner() {

    }

    function closeShort() external onlyOwner() {

    }

    function quoteBalance() public {

    }

    function baseBalance() public {

    }
}