// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "contracts/CustodianFactory.sol";
import "contracts/Beacon.sol";
import "contracts/proxy/TUProxy.sol";
import "contracts/proxy/BUProxy.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
// import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {Custodian} from "contracts/Custodian.sol";

contract TestCustodian is Test {
    event Transfer(address indexed from, address indexed to, uint256 value);

    address beaconOwner;
    address factoryAdmin;
    address factoryProxyAdmin;

    address user1;
    address custodian1;

    address factoryImpl;
    address factory;
    address CustodianImpl;
    address beacon;

    // BASE
    address WETH_USDC_uniPool = 0xd0b53D9277642d899DF5C87A3966A349A798F224;
    address aavePool = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;

    address WETH = 0x4200000000000000000000000000000000000006;
    address aWETH = 0xD4a0e0b9149BCee3C920d2E00b5dE09138fd8bb7;

    address USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address aUSDC = 0x4e65fE4DbA92790696d040ac24Aa414708F5c0AB;

    function setUp() public {
        // prepare BASE network environment
        vm.createSelectFork(vm.envString("LOCAL_RPC"));
        console.log("chain id:", block.chainid);

        user1 = makeAddr("user1");
        beaconOwner = makeAddr("beaconOwner");
        factoryAdmin = makeAddr("factoryAdmin");
        factoryProxyAdmin = makeAddr("factoryProxyAdmin");

        CustodianImpl = address(new Custodian());
        beacon = address(new Beacon(CustodianImpl, beaconOwner));
        vm.label(beacon, "beacon");
        factoryImpl = address(new CustodianFactory());
        vm.label(factoryImpl, "factoryImpl");
        factory = address(
            new TUProxy(
                factoryImpl,
                factoryProxyAdmin,
                abi.encodeCall(
                    CustodianFactory.initialize, (factoryAdmin, beacon, WETH, aWETH, USDC, aUSDC, WETH_USDC_uniPool, aavePool)
                )
            )
        );
        vm.label(factory, "factory");

        deal(WETH, user1, 1 * 10**IERC20Metadata(WETH).decimals());
        deal(USDC, user1, 3000 * 10**IERC20Metadata(USDC).decimals());

        vm.startPrank(user1);
        CustodianFactory(factory).register();
        vm.stopPrank();

        custodian1 = CustodianFactory(factory).UserToAccount(user1);
        vm.label(custodian1, "custodian1");

        vm.startPrank(user1);
        IERC20(WETH).approve(custodian1, type(uint256).max);
        IERC20(USDC).approve(custodian1, type(uint256).max);
        vm.stopPrank();
    }

    function test_public_constant() public {
        ICustodianFactory factoryInstance = ICustodianFactory(factory);
        ICustodian custodian1Instance = ICustodian(custodian1);

        require(factoryInstance.baseToken() == WETH);
        require(factoryInstance.quoteToken() == USDC);
        require(factoryInstance.aBaseToken() == aWETH);
        require(factoryInstance.aQuoteToken() == aUSDC);
        require(factoryInstance.uniPool() == WETH_USDC_uniPool);
        require(factoryInstance.aavePool() == aavePool);

        require(custodian1Instance.factory() == factory);
        require(custodian1Instance.baseReserve() == IERC20(WETH).balanceOf(custodian1));
        require(custodian1Instance.quoteReserve() == IERC20(USDC).balanceOf(custodian1));
    }

    function test_deposit() public {
        vm.startPrank(user1);

        vm.expectEmit(WETH);
        emit Transfer(user1, address(custodian1), IERC20(WETH).balanceOf(user1));
        Custodian(custodian1).deposit(true, IERC20(WETH).balanceOf(user1));

        vm.expectEmit(USDC);
        emit Transfer(user1, address(custodian1), IERC20(USDC).balanceOf(user1));
        Custodian(custodian1).deposit(false, IERC20(USDC).balanceOf(user1));

        vm.stopPrank();
    }

    function test_deposit_withdraw() public {
        test_deposit();

        vm.startPrank(user1);
        emit Transfer(address(this), user1, IERC20(WETH).balanceOf(custodian1));
        Custodian(custodian1).withdraw(true, 0, true);

        emit Transfer(address(this), user1, IERC20(USDC).balanceOf(custodian1));
        Custodian(custodian1).withdraw(false, 0, true);

        vm.stopPrank();
    }

    function test_openLong() public {

    }

    function test_openShort() public {

    }

    function test_closeLong() public {

    }

    function test_closeShort() public {

    }
}
