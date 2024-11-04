// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import {Initializable} from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

import {ICustodian} from "./interfaces/ICustodian.sol";
import {ICustodianFactory} from "./interfaces/ICustodianFactory.sol";
import {IUniswapV3SwapCallback} from "./interfaces/uniswap/callback/IUniswapV3SwapCallback.sol";
import {IUniswapV3Pool} from "./interfaces/uniswap/IUniswapV3Pool.sol";
import {IPool} from "./interfaces/aave/IPool.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import "forge-std/Test.sol";

contract Custodian is ICustodian, Initializable, ReentrancyGuardUpgradeable, IUniswapV3SwapCallback {
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
    error ClosePositionFailed();

    event OpenLong(uint256 baseStaked, uint256 quoteDebt);
    event OpenShort(uint256 quoteStaked, uint256 baseDebt);
    event CloseLong();
    event CloseShort();

    enum Action {
        OPENLONG,
        OPENSHORT,
        CLOSELONG,
        CLOSESHORT
    }

    modifier onlyUser() {
        require(msg.sender == ICustodianFactory(factory).AccountToUser(address(this)), NotUser());
        _;
    }

    constructor() {
        _disableInitializers();
    }

    function initialize(address _factory) external initializer {
        factory = _factory;
        isBaseZero = _baseToken() < _quoteToken() ? true : false;
        // console.log("isBaseZero:", isBaseZero);
        __ReentrancyGuard_init();
    }

    function baseReserve() public returns (uint256) {
        return IERC20(_baseToken()).balanceOf(address(this));
    }

    function quoteReserve() public returns (uint256) {
        return IERC20(_quoteToken()).balanceOf(address(this));
    }

    function deposit(bool isBase, uint256 amount) external onlyUser nonReentrant {
        address token = isBase ? _baseToken() : _quoteToken();
        IERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function withdraw(bool isBase, uint256 amount, bool isFullyWithdraw) external onlyUser nonReentrant {
        if (isBase) {
            amount = isFullyWithdraw ? IERC20(_baseToken()).balanceOf(address(this)) : amount;
            IERC20(_baseToken()).transfer(msg.sender, amount);
        } else {
            amount = isFullyWithdraw ? IERC20(_quoteToken()).balanceOf(address(this)) : amount;
            IERC20(_quoteToken()).transfer(msg.sender, amount);
        }
    }

    // keep a few base token as margin, then mortgage in quote token, and borrow more base token
    // ex. WETH/USDC pair, long WETH at $3000,
    // keep 1 WETH as margin,
    // flashswap USDC -> 5 WETH(on Uniswap),
    // use all WETH as margin to borrow USDC(on aave)
    // repay minimum USDC to Uniswap
    // Finally, we have more WETH in collateral.
    function openLong(uint256 leverage) public onlyUser nonReentrant {
        require(!isLongPositionOpen && !isShortPositionOpen, OpenLongFailed());

        uint amount = baseReserve();
        require(amount > 0, NotEnoughMargin(true));

        IUniswapV3Pool(_uniPool()).swap(address(this), isBaseZero ? false : true, -int256(amount * (leverage - 1)), isBaseZero ? 1461446703485210103287273052203988822378723970341 : 4295128740, abi.encode(Action.OPENLONG));
    }

    // keep a few quote token as margin, then mortage in base token, and borrow more quote token
    // ex. WETH/USDC pair, short WETH,
    // keep a few USDC as margin,
    // flashswap WETH -> USDC(on Uniswap),
    // use all USDC as margin to borrow WETH(on aave)
    // repay minimum WETH to Uniswap
    // Finally, we have more USDC in collateral.
    function openShort(uint256 leverage) public onlyUser nonReentrant {
        require(!isLongPositionOpen && !isShortPositionOpen, OpenShortFailed());

        uint amount = quoteReserve();
        require(amount > 0, NotEnoughMargin(false));

        IUniswapV3Pool(_uniPool()).swap(address(this), isBaseZero ? true : false, -int256(amount * (leverage - 1)), isBaseZero ? 4295128740 : 1461446703485210103287273052203988822378723970341, abi.encode(Action.OPENSHORT));
    }

    //
    function closeLong() public onlyUser nonReentrant {
        require(isLongPositionOpen && !isShortPositionOpen, CloseLongFailed());

        uint256 debtAmount = IERC20(_aaveDebtQuoteToken()).balanceOf(address(this));
        require(debtAmount > 0, ClosePositionFailed());

        IUniswapV3Pool(_uniPool()).swap(address(this), isBaseZero ? true : false, -int256(debtAmount), isBaseZero ? 4295128740 : 1461446703485210103287273052203988822378723970341, abi.encode(Action.CLOSELONG));
    }

    function closeShort() public onlyUser nonReentrant {
        require(!isLongPositionOpen && isShortPositionOpen, CloseShortFailed());

        uint256 debtAmount = IERC20(_aaveDebtBaseToken()).balanceOf(address(this));
        require(debtAmount > 0, ClosePositionFailed());

        IUniswapV3Pool(_uniPool()).swap(address(this), isBaseZero ? false : true, -int256(debtAmount), isBaseZero ? 1461446703485210103287273052203988822378723970341 : 4295128740, abi.encode(Action.CLOSESHORT));
    }

    function uniswapV3SwapCallback(int256 amount0Delta, int256 amount1Delta, bytes calldata data) external {
        Action action = abi.decode(data, (Action));
        if (action == Action.OPENLONG) {
            // WETH amount we got
            // uint256 baseOutAmount = uint256(isBaseZero ? -amount0Delta : -amount1Delta);

            // USDC we need to repay to Uniswap
            uint256 quoteInAmount = uint256(isBaseZero ? amount1Delta : amount0Delta);

            uint256 baseAmount = baseReserve();
            IERC20(_baseToken()).approve(_aavePool(), baseAmount);
            IPool(_aavePool()).supply(_baseToken(), baseAmount, address(this), 0);
            IPool(_aavePool()).borrow(_quoteToken(), quoteInAmount, 2, 0, address(this));

            // repay to Uniswap
            IERC20(_quoteToken()).transfer(msg.sender, quoteInAmount);

            isLongPositionOpen = true;
            emit OpenLong(baseAmount, quoteInAmount);
        } else if (action == Action.OPENSHORT) {
            // WETH we need to repay to Uniswap
            uint256 baseInAmount = uint256(isBaseZero ? amount0Delta : amount1Delta);

            uint256 quoteAmount = quoteReserve();
            IERC20(_quoteToken()).approve(_aavePool(), quoteAmount);
            IPool(_aavePool()).supply(_quoteToken(), quoteAmount, address(this), 0);
            IPool(_aavePool()).borrow(_baseToken(), baseInAmount, 2, 0, address(this));

            // repay to Uniswap
            IERC20(_baseToken()).transfer(msg.sender, baseInAmount);

            isShortPositionOpen = true;
            emit OpenShort(quoteAmount, baseInAmount);
        } else if (action == Action.CLOSELONG) {
            // WETH amount we need to repay to Uniswap
            uint256 baseInAmount = uint256(isBaseZero ? amount0Delta : amount1Delta);

            // 还款USDC给aave
            uint256 quoteDebtAmount = IERC20(_aaveDebtQuoteToken()).balanceOf(address(this));
            IERC20(_quoteToken()).approve(_aavePool(), quoteDebtAmount);
            IPool(_aavePool()).repay(_quoteToken(), quoteDebtAmount, 2, address(this));

            // 取出所有的WETH
            uint256 baseOverall = IERC20(_aaveBaseToken()).balanceOf(address(this));
            IERC20(_aaveBaseToken()).approve(_aavePool(), baseOverall);
            IPool(_aavePool()).withdraw(_baseToken(), baseOverall, address(this));

            // repay to Uniswap
            IERC20(_baseToken()).transfer(msg.sender, baseInAmount);

            isLongPositionOpen = false;
            emit CloseLong();
        } else if (action == Action.CLOSESHORT) {
            // USDC amount wee need to repay to Uniswap
            uint256 quoteInAmount = uint256(isBaseZero ? amount1Delta : amount0Delta);

            // 还款WETH给aave
            uint256 baseDebtAmount = IERC20(_aaveDebtBaseToken()).balanceOf(address(this));
            IERC20(_baseToken()).approve(_aavePool(), baseDebtAmount);
            IPool(_aavePool()).repay(_baseToken(), baseDebtAmount, 2, address(this));

            // 取出所有的USDC
            uint256 quoteOverall = IERC20(_aaveQuoteToken()).balanceOf(address(this));
            IERC20(_aaveQuoteToken()).approve(_aavePool(), quoteOverall);
            IPool(_aavePool()).withdraw(_quoteToken(), quoteOverall, address(this));

            // repay to Uniswap
            IERC20(_quoteToken()).transfer(msg.sender, quoteInAmount);

            isShortPositionOpen = false;
            emit CloseShort();
        }
    }

    function _baseToken() private returns (address) {
        return ICustodianFactory(factory).baseToken();
    }

    function _aaveBaseToken() private returns (address) {
        return ICustodianFactory(factory).aaveBaseToken();
    }

    function _aaveDebtBaseToken() private returns (address) {
        return ICustodianFactory(factory).aaveDebtBaseToken();
    }

    function _quoteToken() private returns (address) {
        return ICustodianFactory(factory).quoteToken();
    }

    function _aaveQuoteToken() private returns (address) {
        return ICustodianFactory(factory).aaveQuoteToken();
    }

    function _aaveDebtQuoteToken() private returns (address) {
        return ICustodianFactory(factory).aaveDebtQuoteToken();
    }

    function _uniPool() private returns (address) {
        return ICustodianFactory(factory).uniPool();
    }

    function _aavePool() private returns (address) {
        return ICustodianFactory(factory).aavePool();
    }
}
