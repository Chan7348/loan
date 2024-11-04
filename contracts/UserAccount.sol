// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {IUserAccount} from "./interfaces/IUserAccount.sol";
import {IUserAccountFactory} from "./interfaces/IUserAccountFactory.sol";
import {IUniswapV3SwapCallback} from "./interfaces/uniswap/callback/IUniswapV3SwapCallback.sol";
import {IUniswapV3Pool} from "./interfaces/uniswap/IUniswapV3Pool.sol";
import {IPool} from "./interfaces/aave/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "forge-std/Test.sol";

contract UserAccount is IUserAccount, Initializable, ReentrancyGuardUpgradeable, IUniswapV3SwapCallback {
    address public factory;

    bool public isLongPositionOpen;
    bool public isShortPositionOpen;
    bool private isBaseZero; // identify during swap on Uniswap

    error OpenLongFailed();
    error OpenShortFailed();
    error CloseLongFailed();
    error CloseShortFailed();
    error NotEnoughMargin(bool isBase);
    error NotUser();

    enum Action {
        OPENLONG,
        OPENSHORT,
        CLOSELONG,
        CLOSESHORT
    }

    modifier onlyUser() {
        require(msg.sender == IUserAccountFactory(factory).AccountToUser(address(this)), NotUser());
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _factory) external initializer {
        factory = _factory;
        address baseToken = IUserAccountFactory(factory).baseToken();
        address quoteToken = IUserAccountFactory(factory).quoteToken();
        isBaseZero = baseToken < quoteToken ? true : false;
        // console.log("isBaseZero:", isBaseZero);
        __ReentrancyGuard_init();
    }

    function deposit(bool isBase, uint256 amount) external onlyUser nonReentrant {
        address aavePool = IUserAccountFactory(factory).aavePool();
        address token = isBase ? IUserAccountFactory(factory).baseToken() : IUserAccountFactory(factory).quoteToken();

        IERC20(token).transferFrom(msg.sender, address(this), amount);
        IERC20(token).approve(aavePool, amount);
        IPool(aavePool).supply(token, amount, address(this), 0);
        // IPool(aavePool).setUserUseReserveAsCollateral(token, true);
    }

    function withdraw(bool isBase, uint256 amount) external onlyUser nonReentrant {
        if (isBase) {
            address baseToken = IUserAccountFactory(factory).baseToken();
            IERC20(baseToken).transfer(msg.sender, amount);
        } else {
            address quoteToken = IUserAccountFactory(factory).quoteToken();
            IERC20(quoteToken).transfer(msg.sender, amount);
        }
    }

    // keep a few base token as margin, then mortgage in quote token, and borrow more base token
    // ex. WETH/USDC pair, long WETH,
    // keep a few WETH as margin,
    // flashswap USDC -> WETH(on Uniswap),
    // use all WETH as margin to borrow USDC(on aave)
    // repay minimum USDC to Uniswap
    // Finally, we have more WETH in collateral.
    function openLong() external onlyUser nonReentrant {
        require(!isLongPositionOpen && !isShortPositionOpen, OpenLongFailed());

        uint balance = IERC20(IUserAccountFactory(factory).baseToken()).balanceOf(address(this));

        require(balance > 0, NotEnoughMargin(true));
        address uniPool = IUserAccountFactory(factory).uniPool();
        IUniswapV3Pool(uniPool).swap(
            address(this), // recipient
            isBaseZero ? false : true, // zeroForOne
            -int256(balance), // amountSpecified
            1461446703485210103287273052203988822378723970341, // minimum sqrtPriceLimitX96
            abi.encode(Action.OPENLONG) // callback data
        );
    }

    // keep a few quote token as margin, then mortage in base token, and borrow more quote token
    // ex. WETH/USDC pair, short WETH,
    // keep a few USDC as margin,
    // flashswap WETH -> USDC(on Uniswap),
    // use all USDC as margin to borrow WETH(on aave)
    // repay minimum WETH to Uniswap
    // Finally, we have more USDC in collateral.
    function openShort() external onlyUser nonReentrant {
        require(!isLongPositionOpen && !isShortPositionOpen, OpenShortFailed());
    }

    function closeLong() external onlyUser nonReentrant {
        require(isLongPositionOpen && !isShortPositionOpen, CloseLongFailed());
    }

    function closeShort() external onlyUser nonReentrant {
        require(!isLongPositionOpen && isShortPositionOpen, CloseShortFailed());
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        address baseToken = IUserAccountFactory(factory).baseToken();
        address quoteToken = IUserAccountFactory(factory).quoteToken();
        address aavePool = IUserAccountFactory(factory).aavePool();
        Action action = abi.decode(data, (Action));
        if (action == Action.OPENLONG) {
            // WETH amount we got
            // uint256 baseOutAmount = uint256(isBaseZero ? -amount0Delta : -amount1Delta);
            // USDC we need to repay to Uniswap
            uint256 quoteInAmount = uint256(isBaseZero ? amount1Delta : amount0Delta);

            uint256 baseAmount = IERC20(baseToken).balanceOf(address(this));

            IERC20(baseToken).approve(aavePool, baseAmount);
            IPool(aavePool).supply(baseToken, baseAmount, address(this), 0);
            IPool(aavePool).borrow(quoteToken, quoteInAmount, 2, 0, address(this));

            // repay to Uniswap
            IERC20(quoteToken).transfer(msg.sender, quoteInAmount);
        }
    }
}
