// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.18;

// 1.Deploy mocks when we are a local anvil chain 当处于anvil链时，我们将部署模拟合约供我们与之交互
// 2.keep track of contract address across different chains 将在不同链上跟踪合约地址
// Sepolia ETH/USD
// Mainnet ETH/USD
import {Script} from "forge-std/Script.sol";
import {MockV3Aggregator} from "../test/mock/MockV3Aggregator.sol";

contract HelpConfig {
    struct NetworkConfig {
        address priceFeed; // ETH/USD
    }

    NetworkConfig public activeNetworkConfig;
    address constant SEPOLIA_PRICE_FEED =
        0x694AA1769357215DE4FAC081bf1f309aDC325306;
    address constant ETH_MAINNET_PRICE_FEED =
        0x5f4eC3Df9cbd43714FE2740f5E3616155c5b8419;

    int256 constant INITIAL_FEED_PRICE = 2000e8;

    constructor() {
        if (block.chainid == 11155111) {
            // sepolia 测试网络
            activeNetworkConfig = getSeopliaEthConfig();
        } else if (block.chainid == 1) {
            // eth 主网
            activeNetworkConfig = getMainnetEthConfig();
        } else {
            // anvil本地
            activeNetworkConfig = getAnvilConfig();
        }
    }

    function getSeopliaEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory sepoliaConfig = NetworkConfig({
            priceFeed: SEPOLIA_PRICE_FEED // Sepolia 上的ETH/USD 合约地址
        });
        return sepoliaConfig;
    }

    function getMainnetEthConfig() public pure returns (NetworkConfig memory) {
        NetworkConfig memory ethConfig = NetworkConfig({
            priceFeed: ETH_MAINNET_PRICE_FEED // ETH主网 上的ETH/USD 合约地址
        });
        return ethConfig;
    }

    function getAnvilConfig() public returns (NetworkConfig memory) {
        // 部署模拟合约，初始价格设为2000美元，精度8位
        MockV3Aggregator mock = new MockV3Aggregator(8, INITIAL_FEED_PRICE);

        NetworkConfig memory anvilConfig = NetworkConfig({
            priceFeed: address(mock)
        });

        return anvilConfig;
    }
}
