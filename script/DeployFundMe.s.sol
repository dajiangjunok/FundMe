// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

import {Script} from "forge-std/Script.sol";
import {FundMe} from "../src/FundMe.sol";
import {HelpConfig} from "./HelpConfig.s.sol";

contract DeployFundMe is Script {
    function run() external returns (FundMe) {
        // before start broadcast not a "real" tx
        HelpConfig helpConfig = new HelpConfig();
        // 解构，因为只有一个参数，所以省略了小括号
        address ethUsdPriceFeed = helpConfig.activeNetworkConfig();

        // after start broadcast real  tx
        vm.startBroadcast();
        FundMe fundMe = new FundMe(ethUsdPriceFeed);
        vm.stopBroadcast();
        return fundMe;
    }
}
