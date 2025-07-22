// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "../src/MemeToken.sol";
import "../src/MemeFactory.sol";
import "../src/interfaces/IUniswapV2Router02.sol";
import "../src/interfaces/IUniswapV2Factory.sol";
import "../src/interfaces/IUniswapV2Pair.sol";

contract PolygonTest is Script {
    function run() external {
        // Handle private key with or without 0x prefix
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 privateKey;
        if (bytes(privateKeyStr).length == 64) {
            privateKey = vm.parseUint(string(abi.encodePacked("0x", privateKeyStr)));
        } else {
            privateKey = vm.parseUint(privateKeyStr);
        }
        address user = vm.addr(privateKey);
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        
        require(block.chainid == 137, "This script is for Polygon Mainnet only");
        require(factoryAddress != address(0), "Please set FACTORY_ADDRESS in .env");
        require(user.balance >= 0.02 ether, "Need at least 0.02 MATIC for testing");
        
        console.log("=== Polygon Mainnet Testing ===");
        console.log("User address:", user);
        console.log("User balance:", user.balance, "MATIC");
        console.log("Factory address:", factoryAddress);
        
        MemeFactory factory = MemeFactory(payable(factoryAddress));
        
        vm.startBroadcast(privateKey);
        
        // Test 1: Deploy a test meme token
        console.log("\n--- Test 1: Deploy Meme Token ---");
        address memeToken = factory.deployMeme(
            "Polygon Test Meme",
            "PTMEME",
            1000000 * 1e18,  // 1M tokens
            0.001 ether      // 0.001 MATIC per token
        );
        console.log("Test token deployed:", memeToken);
        
        // Verify token properties
        MemeToken token = MemeToken(memeToken);
        console.log("Token name:", token.name());
        console.log("Token symbol:", token.symbol());
        
        // Test 2: Mint some tokens
        console.log("\n--- Test 2: Mint Tokens ---");
        uint256 mintAmount = 20 * 1e18; // 20 tokens
        uint256 cost = mintAmount * 0.001 ether / 1e18; // 0.02 MATIC
        
        console.log("Minting", mintAmount / 1e18, "tokens");
        console.log("Cost:", cost, "MATIC");
        
        uint256 balanceBefore = user.balance;
        factory.mintMeme{value: cost}(memeToken, mintAmount);
        uint256 balanceAfter = user.balance;
        
        console.log("MATIC spent:", balanceBefore - balanceAfter);
        console.log("Tokens received:", token.balanceOf(user));
        
        // Check token data
        MemeFactory.TokenData memory tokenData = factory.getTokenData(memeToken);
        console.log("Sold amount:", tokenData.soldAmount / 1e18);
        console.log("Raised MATIC:", tokenData.raisedETH);
        console.log("Liquidity added:", tokenData.liquidityAdded);
        
        vm.stopBroadcast();
        
        console.log("\n=== Test Completed Successfully ===");
    }
    
    function testFullFlow() external {
        // Handle private key with or without 0x prefix
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 privateKey;
        if (bytes(privateKeyStr).length == 64) {
            privateKey = vm.parseUint(string(abi.encodePacked("0x", privateKeyStr)));
        } else {
            privateKey = vm.parseUint(privateKeyStr);
        }
        address user = vm.addr(privateKey);
        address factoryAddress = vm.envAddress("FACTORY_ADDRESS");
        
        require(factoryAddress != address(0), "Please set FACTORY_ADDRESS in .env");
        require(user.balance >= 0.15 ether, "Need at least 0.15 MATIC for full flow test");
        
        console.log("=== Full Flow Test: Deploy -> Mint -> Liquidity -> Buy ===");
        
        MemeFactory factory = MemeFactory(payable(factoryAddress));
        IUniswapV2Router02 router = factory.ROUTER();
        address wmatic = factory.WETH();
        
        vm.startBroadcast(privateKey);
        
        // Step 1: Deploy token
        console.log("\n--- Step 1: Deploy Token ---");
        address memeToken = factory.deployMeme(
            "Full Flow Test",
            "FFTEST",
            10000000 * 1e18,  // 10M tokens
            0.001 ether       // 0.001 MATIC per token
        );
        console.log("Token deployed:", memeToken);
        
        // Step 2: Mint enough to trigger liquidity
        console.log("\n--- Step 2: Trigger Liquidity ---");
        uint256 triggerCost = 0.11 ether; // Should trigger 0.1 MATIC threshold
        uint256 triggerAmount = triggerCost * 1e18 / 0.001 ether;
        
        console.log("Minting", triggerAmount / 1e18, "tokens to trigger liquidity");
        console.log("Cost:", triggerCost, "MATIC");
        
        factory.mintMeme{value: triggerCost}(memeToken, triggerAmount);
        
        // Check if liquidity was added
        MemeFactory.TokenData memory data = factory.getTokenData(memeToken);
        console.log("Liquidity added:", data.liquidityAdded);
        
        if (data.liquidityAdded) {
            address pair = IUniswapV2Factory(router.factory()).getPair(memeToken, wmatic);
            console.log("LP Pair created:", pair);
            
            if (pair != address(0)) {
                uint256 tokenInPair = IERC20(memeToken).balanceOf(pair);
                uint256 maticInPair = IERC20(wmatic).balanceOf(pair);
                console.log("Tokens in pair:", tokenInPair / 1e18);
                console.log("MATIC in pair:", maticInPair / 1e18);
                
                // Step 3: Test buying through QuickSwap
                console.log("\n--- Step 3: Buy via QuickSwap ---");
                uint256 buyAmount = 0.01 ether; // Buy with 0.01 MATIC
                
                address[] memory path = new address[](2);
                path[0] = wmatic;
                path[1] = memeToken;
                
                uint256[] memory amountsOut = router.getAmountsOut(buyAmount, path);
                console.log("Expected tokens from", buyAmount, "MATIC:", amountsOut[1] / 1e18);
                
                uint256 tokenBalanceBefore = IERC20(memeToken).balanceOf(user);
                
                // Buy through factory (which should use QuickSwap)
                factory.buyMeme{value: buyAmount}(memeToken, amountsOut[1] * 95 / 100); // 5% slippage
                
                uint256 tokenBalanceAfter = IERC20(memeToken).balanceOf(user);
                console.log("Tokens bought:", (tokenBalanceAfter - tokenBalanceBefore) / 1e18);
            }
        }
        
        vm.stopBroadcast();
        
        console.log("\n=== Full Flow Test Completed ===");
    }
}