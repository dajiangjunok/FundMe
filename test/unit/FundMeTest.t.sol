// SPDX-License-Identifier:MIT

pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";

// What can we do to work with addresses outside our system?
// 1.Unit
//  - Testing a specific part of our code
// 2. Integration
//  - Testing how our code works with other parts of our code
// 3. Forked
//   - Testing our code on a simulated real environmentStaging
// 4.Staging
//  - Testing our code in a real environment that is not prod

// 我们可以做些什么来处理系统外部的地址？
// 1.Unit
// - 测试代码的特定部分
// 2. Integration
// - 测试我们的代码如何与代码的其他部分协同工作
// 3. Forked
// - 在模拟的真实环境中测试我们的代码
// 4.Staging
// - 在非生产的真实环境中测试我们的代码

contract FundMeTest is Test {
    FundMe fundMe;
    DeployFundMe deployFundMe;
    address USER = makeAddr("user");
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether; // 10e18Wei
    uint256 constant GAS_PRICE = 1;

    // setUp 函数是测试合约最先执行的函数
    function setUp() external {
        deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testMinmumDollarIsFive() public view {
        // assertEq(fundMe.minmumUsd, 5e18)
        console.log("test function testMinmumDollarIsFive is run ...");
        assertEq(fundMe.getMinimumUSD(), 5e18);
    }

    function testOwnerIsMsgSender() public view {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersionIsAccurate() public view {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    // 测试发送资金时，如果发送的资金不足，则会触发断言错误。
    function testFundFailWithoutEnoughEth() public {
        vm.expectRevert(); // the next line should revert
        fundMe.fund(); // send 0 value  // we don't send enough
    }

    function testFundUpdatesFundedDataStructure() public {
        vm.prank(USER);
        // 测试发送资金
        fundMe.fund{value: SEND_VALUE}();

        // uint256 amountFunded = fundMe.getAddressToAmountFunded(msg.sender);// 此时得到的地址是空的
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    // 测试添加资金者到数组中
    function testAddsFunderToArrayOfFunders() public {
        vm.prank(USER); // 指定USER为下一个动作调用者
        fundMe.fund{value: SEND_VALUE}();

        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    modifier funded() {
        vm.prank(USER);
        fundMe.fund{value: SEND_VALUE}();
        _;
    }

    // 测试只有owner可以提现
    function testOnlyOwnerCanWithdraw() public funded {
        // vm.prank(USER); // 指定USER为下一个动作调用者
        // fundMe.fund{value: SEND_VALUE}();

        vm.prank(USER);
        // USER 0x6CA6d1e2D5347Bfab1d91e883F1915560e09129D
        // i_owner 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38
        console.log(msg.sender, fundMe.getOwner());
        vm.expectRevert(); // 断言下一次调用会回滚，无论消息是什么
        fundMe.withdraw();
    }

    // 测试提取金额成功
    function testWithDrawWithASingleFunder() public funded {
        // Arrange 安排（设置测试环境）
        uint256 startingOwnerBalance = fundMe.getOwner().balance; // 获取合约拥有者的余额
        uint256 startingFundMeBalance = address(fundMe).balance; // 获取合约余额

        // Act 行为 （执行想要执行的测试操作）
        vm.prank(fundMe.getOwner()); // 下次调用者为合约拥有者
        fundMe.withdraw(); // 提取资金

        // Assert 断言 （检查测试结果，进行测试断言）
        uint256 endingFundMeBalance = address(fundMe).balance; // 合约余额
        uint256 endingOwnerBalance = fundMe.getOwner().balance; // 合约拥有者的余额
        assertEq(endingFundMeBalance, 0); // 余额提取后应该为0
        assertEq(
            startingOwnerBalance + startingFundMeBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        // Arrange 安排（设置测试环境）
        // vm.prank()
        // vm.deal()
        uint160 startingFundersCount = 10;
        uint160 startingIndex = 1;

        // 用户发送资金
        for (uint160 i = startingIndex; i < startingFundersCount; i++) {
            // 为 i 这个用户注入资金
            hoax(address(i), STARTING_BALANCE);
            // vm.prank(address(i)); // 直接把索引 i 转为地址，用作发送资金的地址
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; // 拥有者的余额
        uint256 startingFundMeBalance = address(fundMe).balance; // 链上的合约余额

        uint256 gasStart = gasleft(); // 获取当前gas值
        vm.txGasPrice(GAS_PRICE);
        // Act 行为 （执行想要执行的测试操作）
        vm.startPrank(fundMe.getOwner());
        // 拥有者提取资金
        fundMe.withdraw();
        vm.stopPrank();

        uint256 gasEnd = gasleft(); // 获取当前gas值，相减得出中间部分耗费gas量，跟tx.gasprice相乘得出总耗费gas量
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gasUsed:", gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance; // 提取操作之后拥有者的余额

        // Assert 断言 （检查测试结果，进行测试断言）
        assertEq(address(fundMe).balance, 0); // 断言链上资金已经被提取完毕
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        ); // 未提取前的资金 +  未提取前拥有者的资金 =  提取后拥有者的资金
    }

    function testWithdrawCheaperFromMultipleFunders() public funded {
        // Arrange 安排（设置测试环境）
        // vm.prank()
        // vm.deal()
        uint160 startingFundersCount = 10;
        uint160 startingIndex = 1;

        // 用户发送资金
        for (uint160 i = startingIndex; i < startingFundersCount; i++) {
            // 为 i 这个用户注入资金
            hoax(address(i), STARTING_BALANCE);
            // vm.prank(address(i)); // 直接把索引 i 转为地址，用作发送资金的地址
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance; // 拥有者的余额
        uint256 startingFundMeBalance = address(fundMe).balance; // 链上的合约余额

        uint256 gasStart = gasleft(); // 获取当前gas值
        vm.txGasPrice(GAS_PRICE);
        // Act 行为 （执行想要执行的测试操作）
        vm.startPrank(fundMe.getOwner());
        // 拥有者提取资金
        fundMe.withdrawCheaper();
        vm.stopPrank();

        uint256 gasEnd = gasleft(); // 获取当前gas值，相减得出中间部分耗费gas量，跟tx.gasprice相乘得出总耗费gas量
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice;
        console.log("gasUsed:", gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance; // 提取操作之后拥有者的余额

        // Assert 断言 （检查测试结果，进行测试断言）
        assertEq(address(fundMe).balance, 0); // 断言链上资金已经被提取完毕
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        ); // 未提取前的资金 +  未提取前拥有者的资金 =  提取后拥有者的资金
    }
}
