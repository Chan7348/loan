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

    event OpenLong(uint256 baseStaked, uint256 quoteDebt);

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
    function openLong(uint256 leverage) external onlyUser nonReentrant {
        require(!isLongPositionOpen && !isShortPositionOpen, OpenLongFailed());

        uint amount = baseReserve();
        require(amount > 0, NotEnoughMargin(true));

        IUniswapV3Pool(_uniPool()).swap(
            address(this), // recipient
            isBaseZero ? false : true, // zeroForOne
            -int256(amount * leverage), // amountSpecified
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
    function openShort(uint256 leverage) external onlyUser nonReentrant {
        require(!isLongPositionOpen && !isShortPositionOpen, OpenShortFailed());
    }

    function closeLong() external onlyUser nonReentrant {
        require(isLongPositionOpen && !isShortPositionOpen, CloseLongFailed());
    }

    function closeShort() external onlyUser nonReentrant {
        require(!isLongPositionOpen && isShortPositionOpen, CloseShortFailed());
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

            emit OpenLong(baseAmount, quoteInAmount);
        }
    }

    function _baseToken() private returns (address) {
        return ICustodianFactory(factory).baseToken();
    }

    function _aBaseToken() private returns (address) {
        return ICustodianFactory(factory).aBaseToken();
    }

    function _quoteToken() private returns (address) {
        return ICustodianFactory(factory).quoteToken();
    }

    function _aQuoteToken() private returns (address) {
        return ICustodianFactory(factory).aQuoteToken();
    }

    function _uniPool() private returns (address) {
        return ICustodianFactory(factory).uniPool();
    }

    function _aavePool() private returns (address) {
        return ICustodianFactory(factory).aavePool();
    }
}
