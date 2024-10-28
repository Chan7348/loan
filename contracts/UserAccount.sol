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

    uint256 public baseBalance;
    uint256 public quoteBalance;

    bool public isPositionOpen;
    bool private isBaseZero; // identify during swap on Uniswap

    error PositionExists();
    error PositionNonexists();
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
        address aavePool = IUserAccountFactory(factory).aavePool();
        IPool(aavePool).setUserUseReserveAsCollateral(baseToken, true);
        IPool(aavePool).setUserUseReserveAsCollateral(quoteToken, true);
        __ReentrancyGuard_init();
    }

    function deposit(bool isBase, uint256 amount) external onlyUser nonReentrant {
        if (isBase) {
            address baseToken = IUserAccountFactory(factory).baseToken();
            IERC20(baseToken).transferFrom(msg.sender, address(this), amount);
            baseBalance += amount;
        } else {
            address quoteToken = IUserAccountFactory(factory).quoteToken();
            IERC20(quoteToken).transferFrom(msg.sender, address(this), amount);
            quoteBalance += amount;
        }
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
        require(!isPositionOpen, PositionExists());
        require(baseBalance > 0, NotEnoughMargin(true));
        address uniPool = IUserAccountFactory(factory).uniPool();
        IUniswapV3Pool(uniPool).swap(
            address(this), // recipient
            isBaseZero ? false : true, // zeroForOne
            -int256(baseBalance), // amountSpecified
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
        require(!isPositionOpen, PositionExists());
    }

    function closeLong() external onlyUser nonReentrant {
        require(isPositionOpen, PositionNonexists());
    }

    function closeShort() external onlyUser nonReentrant {
        require(isPositionOpen, PositionNonexists());
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
