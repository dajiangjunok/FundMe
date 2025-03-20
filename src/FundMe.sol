// Get funds from address
// witndraw funds
// set a minimum funding value in USD

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;
import {PriceCoverter} from "./PriceCoverter.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract FundMe {
    using PriceCoverter for uint256;
    uint256 private constant MINIMUM_USD = 5e18; // 最少$5
    address[] private s_funders;
    mapping(address => uint256) private s_addressToAmountFunds;
    AggregatorV3Interface private s_priceFeed;

    address private immutable i_owner;

    constructor(address priceFeed) {
        i_owner = msg.sender;
        s_priceFeed = AggregatorV3Interface(priceFeed);
    }

    function fund() public payable {
        // require(getCoversionRate (msg.value) >= MINIMUM_USD, "didn't send enough EHT");
        // 接收加密货币，限制最小金额
        require(
            msg.value.getCoversionRate(s_priceFeed) >= MINIMUM_USD,
            "didn't send enough EHT"
        ); // 接收加密货币，限制最小金额

        s_funders.push(msg.sender);

        // 每次函数调用，则映射里面找到对应地址已发送的token，加上此次函数调用新发送的值，用以更新map对象
        s_addressToAmountFunds[msg.sender] =
            s_addressToAmountFunds[msg.sender] +
            msg.value;
    }

    function getVersion() public view returns (uint256) {
        return s_priceFeed.version();
    }

    function withdrawCheaper() public onlyOwner {
        uint256 funders_len = s_funders.length;
        for (
            uint256 _fundIndex = 0;
            _fundIndex < funders_len; // 这样读取storage上的s_funders会在循环里反复消耗高额gas
            _fundIndex++
        ) {
            address funder = s_funders[_fundIndex];
            s_addressToAmountFunds[funder] = 0; // 置空用户发送的funds
        }

        // rest array
        s_funders = new address[](0);

        (bool isCallPayableSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // 有点像设置了一个ABI接口按钮🤔
        require(isCallPayableSuccess, "Call failed");
    }

    function withdraw() public onlyOwner {
        for (
            uint256 _fundIndex = 0;
            _fundIndex < s_funders.length; // 这样读取storage上的s_funders会在循环里反复消耗高额gas
            _fundIndex++
        ) {
            address funder = s_funders[_fundIndex];
            s_addressToAmountFunds[funder] = 0; // 置空用户发送的funds
        }

        // rest array
        s_funders = new address[](0);
        // actually withdraw the funds

        // 提取资金的三种方式
        // // 1.transfer（2300gas, throws error） 最多2300gas 错误会报错回滚
        // payable(msg.sender).transfer(address(this).balance); // msg.sender is address type , translate them payable address type

        // // 2.send （2300gas, boolean） 最多2300gas 错误不会回滚
        // bool isSendPayableSuccess = payable(msg.sender).send(
        //     address(this).balance
        // );
        // require(isSendPayableSuccess, "Send failed");

        // 3.call ( 没有gas限制，返回两个参数) 使用call发送/接收加密货币是推荐的方式
        (bool isCallPayableSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }(""); // 有点像设置了一个ABI接口按钮🤔
        require(isCallPayableSuccess, "Call failed");
    }

    modifier onlyOwner() {
        require(msg.sender == i_owner, "Sender is not owner!");
        _;
    }

    /**
     * getters  view/pure
     */

    function getAddressToAmountFunded(
        address _user
    ) public view returns (uint256) {
        return s_addressToAmountFunds[_user];
    }

    function getFunder(uint256 _index) public view returns (address) {
        return s_funders[_index];
    }

    function getMinimumUSD() public pure returns (uint256) {
        return MINIMUM_USD;
    }

    function getOwner() public view returns (address) {
        return i_owner;
    }
}
