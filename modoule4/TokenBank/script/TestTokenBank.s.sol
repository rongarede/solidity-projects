// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {TokenBank} from "../src/TokenBank.sol";
import {TestToken} from "../src/TestToken.sol";

contract TestTokenBank is Script {
    TokenBank constant tokenBank = TokenBank(0xcB76bF429B49397363c36123DF9c2F93627e4f92);
    TestToken constant testToken = TestToken(0x134bd50D5347eE1aD950Dc79B10d17bD1048c7A1);
    
    address constant deployer = 0x07EDff51D7ac57A6dA659be761DD28860A1342fd;
    uint256 constant depositAmount = 1000 * 10**18; // 1000 tokens
    uint256 constant withdrawAmount = 500 * 10**18; // 500 tokens

    function run() external {
        vm.startBroadcast();
        
        console.log("=== TokenBank Contract Test ===");
        console.log("TokenBank address:", address(tokenBank));
        console.log("TestToken address:", address(testToken));
        console.log("Deployer address:", deployer);
        
        // Step 1: Check initial balances
        console.log("\n=== Step 1: Initial Balances ===");
        uint256 tokenBalance = testToken.balanceOf(deployer);
        uint256 bankBalance = tokenBank.getBalance(deployer, address(testToken));
        console.log("Deployer token balance:", tokenBalance);
        console.log("Deployer bank balance:", bankBalance);
        
        // Step 2: Approve TokenBank to spend tokens
        console.log("\n=== Step 2: Approve TokenBank ===");
        testToken.approve(address(tokenBank), depositAmount);
        uint256 allowance = testToken.allowance(deployer, address(tokenBank));
        console.log("Allowance granted:", allowance);
        
        // Step 3: Test deposit function
        console.log("\n=== Step 3: Test Deposit ===");
        console.log("Depositing", depositAmount, "tokens...");
        tokenBank.deposit(address(testToken), depositAmount);
        
        // Check balances after deposit
        uint256 tokenBalanceAfterDeposit = testToken.balanceOf(deployer);
        uint256 bankBalanceAfterDeposit = tokenBank.getBalance(deployer, address(testToken));
        uint256 contractTokenBalance = testToken.balanceOf(address(tokenBank));
        
        console.log("Deployer token balance after deposit:", tokenBalanceAfterDeposit);
        console.log("Deployer bank balance after deposit:", bankBalanceAfterDeposit);
        console.log("TokenBank contract token balance:", contractTokenBalance);
        
        // Step 4: Test getBalance function
        console.log("\n=== Step 4: Test GetBalance ===");
        uint256 queriedBalance = tokenBank.getBalance(deployer, address(testToken));
        console.log("Queried balance:", queriedBalance);
        
        // Step 5: Test withdraw function
        console.log("\n=== Step 5: Test Withdraw ===");
        console.log("Withdrawing", withdrawAmount, "tokens...");
        tokenBank.withdraw(address(testToken), withdrawAmount);
        
        // Check final balances
        uint256 finalTokenBalance = testToken.balanceOf(deployer);
        uint256 finalBankBalance = tokenBank.getBalance(deployer, address(testToken));
        uint256 finalContractBalance = testToken.balanceOf(address(tokenBank));
        
        console.log("Final deployer token balance:", finalTokenBalance);
        console.log("Final deployer bank balance:", finalBankBalance);
        console.log("Final TokenBank contract balance:", finalContractBalance);
        
        // Verify results
        console.log("\n=== Verification ===");
        console.log("Expected bank balance:", depositAmount - withdrawAmount);
        console.log("Actual bank balance:", finalBankBalance);
        console.log("Test passed:", finalBankBalance == (depositAmount - withdrawAmount));
        
        vm.stopBroadcast();
    }
}