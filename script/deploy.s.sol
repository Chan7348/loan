// SPDX-License-Identifier: MIT
pragma solidity 0.8.27;

import "forge-std/Script.sol";
import { TUProxy } from "contracts/proxy/TUProxy.sol";
import { BUProxy } from "contracts/proxy/BUProxy.sol";
import { Beacon } from "contracts/Beacon.sol";
import { Custodian } from "contracts/Custodian.sol";
import { CustodianFactory } from "contracts/CustodianFactory.sol";
contract Deploy is Script {

    address public near1;
    address public near2;
    address public user1;

    // sepolia addresses
    address WETH_USDC_uniPool;
    address aavePool;

    address WETH;
    address aaveWETH;
    address aaveDebtWETH;

    address USDC;
    address aaveUSDC;
    address aaveDebtUSDC;

    address beaconOwner;
    address factoryAdmin;
    address factoryProxyAdmin;

    function setUp() public {
        WETH_USDC_uniPool = 0xd37AC323adF2B42ACde752e765feb586Fa9B450F;
        aavePool = 0x6Ae43d3271ff6888e7Fc43Fd7321a503ff738951;
        WETH = 0xC558DBdd856501FCd9aaF1E62eae57A9F0629a3c;
        aaveWETH = 0x5b071b590a59395fE4025A0Ccc1FcC931AAc1830;
        aaveDebtWETH = 0x22a35DB253f4F6D0029025D6312A3BdAb20C2c6A;
        USDC = 0x94a9D9AC8a22534E3FaCa9F4e7F2E2cf85d5E4C8;
        aaveUSDC = 0x16dA4541aD1807f4443d92D26044C1147406EB80;
        aaveDebtUSDC = 0x36B5dE936eF1710E1d22EabE5231b28581a92ECc;

        near1 = vm.addr(vm.envUint("near1"));
        near2 = vm.addr(vm.envUint("near2"));

        beaconOwner = near2;
        factoryAdmin = near1;
        factoryProxyAdmin = near2;
        user1 = near1;

    }

    function run() public {
        vm.startBroadcast(vm.envUint("near1"));

        address custodianImpl = address(new Custodian());
        console.log("custodianImpl", custodianImpl);

        address beacon = address(new Beacon(custodianImpl, beaconOwner));
        console.log("beacon", beacon);

        address factoryImpl = address(new CustodianFactory());
        console.log("factoryImpl", factoryImpl);

        address factory = address(
            new TUProxy(
                factoryImpl,
                factoryProxyAdmin,
                abi.encodeCall(
                    CustodianFactory.initialize, (factoryAdmin, beacon, WETH, USDC, WETH_USDC_uniPool, aavePool)
                )
            )
        );
        console.log("factory", factory);

        vm.stopBroadcast();
    }
}