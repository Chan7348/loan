// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IAccount} from "./interfaces/IAccount.sol";
import {IUniswapV3SwapCallback} from "./interfaces/uniswap/callback/IUniswapV3SwapCallback.sol";
import {IUniswapV3Pool} from "./interfaces/uniswap/IUniswapV3Pool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

contract Account is IAccount, Initializable, ReentrancyGuardUpgradeable, IUniswapV3SwapCallback {
    address public factory;
    address public user;
    address public baseToken;
    address public quoteToken;
    address public uniPool;
    address public aavePool;

    uint public baseBalance;
    uint public quoteBalance;

    bool public ispositionOpen;

    error PositionExists();
    error PositionNonexists();

    modifier onlyUser() {
        require(msg.sender == user, NotUser());
        _;
    }

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
        __ReentrancyGuard_init();
    }

    function deposit(bool isBase, uint amount) external onlyUser() nonReentrant() {
        if (isBase) {
            IERC20(baseToken).transferFrom(msg.sender, address(this), amount);
            baseBalance += amount;
        } else {
            IER20(quoteToken).transferFrom(msg.sender, address(this), amount);
            quoteBalance += amount;
        }
    }

    function withdraw(bool isBase, uint amount) external onlyUser() nonReentrant() {
        if (isBase) {
            IERC20(baseToken).transfer(msg.sender, )
        }
    }

    // keep a few base token as margin, then mortgage in quote token, and borrow more base token
    // ex. WETH/USDC pair, long WETH,
    // keep a few WETH as margin,
    // flashswap USDC -> WETH(on Uniswap),
    // use all WETH as margin to borrow USDC(on aave)
    // repay minimum USDC to Uniswap
    // Finally, we have more WETH in collateral.
    function openLong() external onlyUser() nonReentrant() {
        require(!isPositionOpen, PositionExists());

    }

    // keep a few quote token as margin, then mortage in base token, and borrow more quote token
    // ex. WETH/USDC pair, short WETH,
    // keep a few USDC as margin,
    // flashswap WETH -> USDC(on Uniswap),
    // use all USDC as margin to borrow WETH(on aave)
    // repay minimum WETH to Uniswap
    // Finally, we have more USDC in collateral.
    function openShort() external onlyUser() nonReentrant() {
        require(!isPositionOpen, PositionExists());
    }

    function closeLong() external onlyUser() nonReentrant() {
        require(ispositionOpen, PositionNonexists());
    }

    function closeShort() external onlyUser() nonReentrant() {
        require(ispositionOpen, PositionNonexists());
    }

    function uniswapV3SwapCallback(int amount0Delta, int amount1Delta, bytes calldata data) external {

    }
}