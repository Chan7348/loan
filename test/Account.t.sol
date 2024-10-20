// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "contracts/UserAccountFactory.sol";
import "contracts/Beacon.sol";
import "contracts/proxy/TUProxy.sol";
import "contracts/proxy/BUProxy.sol";
import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";
import {UserAccount} from "contracts/UserAccount.sol";

contract TestUserAccount is Test {
    address beaconOwner;
    address factoryAdmin;
    address factoryProxyAdmin;
    address userA;

    address factoryImpl;
    address factory;
    address UserAccountImpl;
    address beacon;
    address WETH_USDC_uniPool;
    address WETH_USDC_aavePool;
    address WETH = 0x4200000000000000000000000000000000000006;
    address USDC = 0x833589fCD6eDb6E08f4c7C32D4f71b54bdA02913;

    function setUp() public {
        // prepare BASE network environment
        vm.createSelectFork(vm.envString("BASE_RPC"));
        console.log("chain id:", block.chainid);

        userA = makeAddr("userA");
        beaconOwner = makeAddr("beaconOwner");
        factoryAdmin = makeAddr("factoryAdmin");
        factoryProxyAdmin = makeAddr("factoryProxyAdmin");
        UserAccountImpl = address(new UserAccount());
        beacon = address(new Beacon(UserAccountImpl, beaconOwner));
        factoryImpl = address(new UserAccountFactory());
        factory = address(
            new TUProxy(
                factoryImpl,
                factoryProxyAdmin,
                abi.encodeCall(UserAccountFactory.initialize, (factoryAdmin, beacon, WETH, USDC))
            )
        );

        vm.startPrank(userA);
        UserAccountFactory(factory).register();
        vm.stopPrank();
    }

    function test_init() public {
        address userAAccountAddr = UserAccountFactory(factory).UserAccounts(userA);
        console.log("User A account:", userAAccountAddr);

        uint256 decimals = IERC20Metadata(WETH).decimals();
        console.log(decimals);

        deal(WETH, userA, 4 * IERC20Metadata(WETH).decimals());

        vm.startPrank(userA);
        IERC20(WETH).approve(userAAccountAddr, type(uint256).max);
        UserAccount(userAAccountAddr).deposit(true, IERC20(WETH).balanceOf(userA));
        UserAccount(userAAccountAddr).openLong();
        vm.stopPrank();
    }
}
