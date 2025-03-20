// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

library PriceCoverter {
    function getPrice(
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // 获得最新的以太坊 -> usd 价格，单位wei
        // AggregatorV3Interface priceFeed = AggregatorV3Interface(
        //     0x694AA1769357215DE4FAC081bf1f309aDC325306
        // );

        (, int256 price, , , ) = priceFeed.latestRoundData();
        // 得到 1890. 00000000 美元 = 1ETH = 1*1e8 wei    1890 / 1e18 = 1 wei
        return uint256(price * 1e10); // 得到的price  其实是实际1eth价格的 1e18倍
    }

    function getCoversionRate(
        uint256 _amountEth,
        AggregatorV3Interface priceFeed
    ) internal view returns (uint256) {
        // 将用户输入的ETH数量(单位是wei)转化为usd
        uint256 ethPrice = getPrice(priceFeed);
        uint256 amountEthInUsd = (ethPrice * _amountEth) / 1e18; // 2个变量都扩大1e18倍，同时除掉就是单个以太坊乘以太坊单个价格
        return amountEthInUsd;
    }
}
