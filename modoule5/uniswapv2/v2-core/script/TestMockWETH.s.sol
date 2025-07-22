// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../test/mocks/MockWETH.sol";
import "../contracts/UniswapV2Router02.sol";
import "../test/mocks/MockERC20.sol";

contract TestMockWETH is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // From contracts-addresses.json (updated addresses)
        address factory = 0x2E2812638232c64eeC81B4a2DFd4ca975887d571;
        address mockWETHAddress = 0x7Ff8501f89DBFde83ad5b46ce04a508403a28700;
        address routerAddress = 0xcEc76053fBa3fDB41570B816bc42d4DB7497bC72;
        
        vm.startBroadcast(deployerPrivateKey);
        
        MockWETH mockWETH = MockWETH(payable(mockWETHAddress));
        UniswapV2Router02 router = UniswapV2Router02(payable(routerAddress));
        
        console.log("Testing MockWETH functionality...");
        console.log("MockWETH address:", address(mockWETH));
        console.log("Router address:", address(router));
        console.log("Router WETH address:", router.WETH());
        
        // Test 1: Verify Router is configured with correct MockWETH
        require(router.WETH() == address(mockWETH), "Router WETH mismatch");
        console.log("Router correctly configured with MockWETH");
        
        // Test 2: Test MockWETH deposit functionality
        uint256 depositAmount = 0.1 ether;
        uint256 balanceBefore = mockWETH.balanceOf(tx.origin);
        
        mockWETH.deposit{value: depositAmount}();
        uint256 balanceAfter = mockWETH.balanceOf(tx.origin);
        
        require(balanceAfter == balanceBefore + depositAmount, "MockWETH deposit failed");
        console.log("MockWETH deposit functionality works");
        console.log("  Deposited:", depositAmount);
        console.log("  New WETH balance:", balanceAfter);
        
        // Test 3: Test MockWETH withdraw functionality
        uint256 withdrawAmount = depositAmount / 2;
        uint256 ethBalanceBefore = tx.origin.balance;
        
        mockWETH.withdraw(withdrawAmount);
        uint256 ethBalanceAfter = tx.origin.balance;
        uint256 wethBalanceAfter = mockWETH.balanceOf(tx.origin);
        
        require(ethBalanceAfter >= ethBalanceBefore, "ETH not returned on withdraw");
        require(wethBalanceAfter == balanceAfter - withdrawAmount, "WETH balance incorrect after withdraw");
        console.log("MockWETH withdraw functionality works");
        console.log("  Withdrawn:", withdrawAmount);
        console.log("  Remaining WETH balance:", wethBalanceAfter);
        
        // Test 4: Test ERC20 functionality
        address testReceiver = 0x742d35Cc6635c0532925A3b8Bc9C5C6F8F5B5b0b; // Random address
        uint256 transferAmount = 1000;
        
        mockWETH.transfer(testReceiver, transferAmount);
        require(mockWETH.balanceOf(testReceiver) == transferAmount, "Transfer failed");
        console.log("MockWETH ERC20 transfer functionality works");
        
        vm.stopBroadcast();
        
        console.log("=== MockWETH Integration Test Results ===");
        console.log("All MockWETH functionality tests passed!");
        console.log("Router is properly configured with MockWETH");
        console.log("MockWETH successfully replaces Base mainnet WETH");
        console.log("System ready for testing without real ETH dependency");
    }
}