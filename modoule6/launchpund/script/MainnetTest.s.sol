// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "forge-std/Script.sol";
import "../src/MemeToken.sol";
import "../src/MemeFactory.sol";
import "../src/interfaces/IUniswapV2Router02.sol";
import "../src/interfaces/IUniswapV2Factory.sol";

contract MainnetTest is Script {
    function run() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(privateKey);
        
        console.log("=== Mainnet Testing ===");
        console.log("User address:", user);
        console.log("User balance:", user.balance);
        console.log("Chain ID:", block.chainid);
        
        // You need to provide deployed addresses here
        // Or read from previous deployment
        address factoryAddress = vm.envOr("FACTORY_ADDRESS", address(0));
        require(factoryAddress != address(0), "Please set FACTORY_ADDRESS in .env");
        
        MemeFactory factory = MemeFactory(factoryAddress);
        
        console.log("Factory address:", address(factory));
        console.log("Platform wallet:", factory.platformWallet());
        
        vm.startBroadcast(privateKey);
        
        // Test 1: Deploy a meme token
        string memory tokenName = vm.envString("TEST_TOKEN_NAME");
        string memory tokenSymbol = vm.envString("TEST_TOKEN_SYMBOL");
        uint256 tokenSupply = vm.envUint("TEST_TOKEN_SUPPLY");
        uint256 tokenPrice = vm.envUint("TEST_TOKEN_PRICE");
        
        console.log("Deploying test token...");
        address memeToken = factory.deployMeme(
            tokenName,
            tokenSymbol,
            tokenSupply,
            tokenPrice
        );
        console.log("Test token deployed:", memeToken);
        
        // Test 2: Mint some tokens
        uint256 mintAmount = 10 * 1e18; // 10 tokens
        uint256 cost = mintAmount * tokenPrice / 1e18;
        
        console.log("Minting", mintAmount / 1e18, "tokens...");
        console.log("Cost:", cost);
        
        require(user.balance >= cost, "Insufficient balance for minting");
        
        factory.mintMeme{value: cost}(memeToken, mintAmount);
        
        // Verify results
        uint256 userTokenBalance = IERC20(memeToken).balanceOf(user);
        console.log("User token balance:", userTokenBalance);
        
        MemeFactory.TokenData memory tokenData = factory.getTokenData(memeToken);
        console.log("Sold amount:", tokenData.soldAmount);
        console.log("Raised ETH:", tokenData.raisedETH);
        console.log("Liquidity added:", tokenData.liquidityAdded);
        
        vm.stopBroadcast();
        
        console.log("=== Test Completed Successfully ===");
    }
    
    function testLiquidityTrigger() external {
        uint256 privateKey = vm.envUint("PRIVATE_KEY");
        address user = vm.addr(privateKey);
        address factoryAddress = vm.envOr("FACTORY_ADDRESS", address(0));
        
        require(factoryAddress != address(0), "Please set FACTORY_ADDRESS in .env");
        require(user.balance >= 0.12 ether, "Need at least 0.12 ETH for liquidity test");
        
        MemeFactory factory = MemeFactory(factoryAddress);
        
        console.log("=== Liquidity Trigger Test ===");
        
        vm.startBroadcast(privateKey);
        
        // Deploy token for liquidity test
        address liquidityToken = factory.deployMeme(
            "Liquidity Test Token",
            "LTEST",
            1000000 * 1e18,
            0.001 ether
        );
        
        // Calculate amount needed to trigger liquidity (0.1 ETH raised = ~0.105 ETH cost)
        uint256 triggerCost = 0.11 ether; // Slightly above threshold
        uint256 triggerAmount = triggerCost * 1e18 / 0.001 ether;
        
        console.log("Triggering liquidity with cost:", triggerCost);
        console.log("Token amount:", triggerAmount);
        
        factory.mintMeme{value: triggerCost}(liquidityToken, triggerAmount);
        
        // Check if liquidity was added
        MemeFactory.TokenData memory data = factory.getTokenData(liquidityToken);
        console.log("Liquidity added:", data.liquidityAdded);
        
        if (data.liquidityAdded) {
            // Get pair address
            IUniswapV2Router02 router = factory.ROUTER();
            address weth = factory.WETH();
            address pair = IUniswapV2Factory(router.factory()).getPair(liquidityToken, weth);
            console.log("LP Pair created:", pair);
            
            // Check pair liquidity
            if (pair != address(0)) {
                uint256 pairBalance = IERC20(liquidityToken).balanceOf(pair);
                console.log("Token balance in pair:", pairBalance);
            }
        }
        
        vm.stopBroadcast();
        
        console.log("=== Liquidity Test Completed ===");
    }
}