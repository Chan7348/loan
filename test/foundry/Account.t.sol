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
    address USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;
    address aWETH = 0xD4a0e0b9149BCee3C920d2E00b5dE09138fd8bb7;
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
        factoryImpl = address(new CustodianFactory());
        factory = address(
            new TUProxy(
                factoryImpl,
                factoryProxyAdmin,
                abi.encodeCall(
                    CustodianFactory.initialize, (factoryAdmin, beacon, WETH, USDC, aUSDC, WETH_USDC_uniPool, aavePool)
                )
            )
        );

        vm.startPrank(user1);
        CustodianFactory(factory).register();
        vm.stopPrank();
    }

    function test_init() public {
        address custodian1 = CustodianFactory(factory).UserToAccount(user1);
        console.log("User1 Custodian contract:", custodian1);

        uint256 decimals = IERC20Metadata(WETH).decimals();
        console.log(decimals);

        deal(WETH, user1, 4 * 10 ** IERC20Metadata(WETH).decimals());

        vm.startPrank(user1);
        IERC20(WETH).approve(custodian1, type(uint256).max);

        vm.expectEmit(aWETH);
        emit Transfer(address(0), address(custodian1), IERC20(WETH).balanceOf(user1));
        Custodian(custodian1).deposit(true, IERC20(WETH).balanceOf(user1));
        Custodian(custodian1).openLong();
        vm.stopPrank();
        console.log("user1 Custodian owns aWETH:", IERC20(aWETH).balanceOf(custodian1));
    }

    function test_deposit_base() public {}
}
