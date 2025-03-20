// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract MockV3Aggregator is AggregatorV3Interface {
    // 模拟Chainlink的V3接口，允许设置初始价格和精度
    uint8 public immutable decimals;
    int256 private _latestAnswer;
    uint256 private _latestTimestamp;
    uint80 private _latestRoundId;

    constructor(uint8 _decimals, int256 _initialAnswer) {
        decimals = _decimals;
        _latestAnswer = _initialAnswer;
        _latestTimestamp = block.timestamp;
        _latestRoundId = 1;
    }

    // 函数用于在测试中动态更新价格。
    function updateAnswer(int256 _answer) public {
        _latestAnswer = _answer;
        _latestTimestamp = block.timestamp;
        _latestRoundId++;
    }

    // 返回预设的最新价格数据。
    function latestRoundData()
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        return (
            _latestRoundId,
            _latestAnswer,
            _latestTimestamp,
            _latestTimestamp,
            _latestRoundId
        );
    }

    function getRoundData(
        uint80 _roundId
    )
        external
        view
        override
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        )
    {
        require(_roundId == _latestRoundId, "Round not found");
        return (
            _latestRoundId,
            _latestAnswer,
            _latestTimestamp,
            _latestTimestamp,
            _latestRoundId
        );
    }

    function description() external pure override returns (string memory) {
        return "Mock V3 Aggregator";
    }

    function version() external pure override returns (uint256) {
        return 4;
    }
}
