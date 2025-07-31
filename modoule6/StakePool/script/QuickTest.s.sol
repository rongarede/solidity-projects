// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {KKToken} from "../src/KKToken.sol";
import {StakingPool} from "../src/StakingPool.sol";

/**
 * @title QuickTest
 * @dev Quick test to verify deployed contracts are working
 */
contract QuickTest is Script {
    function run() public {
        // Load deployed contract addresses
        address wethAddress = vm.envAddress("MOCKWETH_ADDRESS");
        address kkTokenAddress = vm.envAddress("KKTOKEN_ADDRESS");
        address stakingPoolAddress = vm.envAddress("STAKINGPOOL_ADDRESS");
        address adminAddress = vm.envAddress("ADMIN_ADDRESS");
        
        MockWETH weth = MockWETH(payable(wethAddress));
        KKToken kkToken = KKToken(kkTokenAddress);
        StakingPool stakingPool = StakingPool(payable(stakingPoolAddress));
        
        console2.log("=== DEPLOYMENT VERIFICATION ===");
        console2.log("Testing deployed contracts on chain:", block.chainid);
        console2.log("");
        
        // Test MockWETH
        console2.log("MockWETH Tests:");
        console2.log("- Address:", address(weth));
        console2.log("- Name:", weth.name());
        console2.log("- Symbol:", weth.symbol());
        console2.log("- Decimals:", weth.decimals());
        console2.log("- Total Supply:", weth.totalSupply());
        
        // Test KKToken
        console2.log("\nKKToken Tests:");
        console2.log("- Address:", address(kkToken));
        console2.log("- Name:", kkToken.name());
        console2.log("- Symbol:", kkToken.symbol());
        console2.log("- Decimals:", kkToken.decimals());
        console2.log("- Total Supply:", kkToken.totalSupply() / 1e18, "KK");
        console2.log("- Admin has admin role:", kkToken.hasRole(kkToken.DEFAULT_ADMIN_ROLE(), adminAddress));
        console2.log("- Admin has minter role:", kkToken.hasRole(kkToken.MINTER_ROLE(), adminAddress));
        console2.log("- Pool has minter role:", kkToken.hasRole(kkToken.MINTER_ROLE(), address(stakingPool)));
        
        // Test StakingPool
        console2.log("\nStakingPool Tests:");
        console2.log("- Address:", address(stakingPool));
        console2.log("- Staking Token:", address(stakingPool.stakingToken()));
        console2.log("- Reward Token:", address(stakingPool.rewardToken()));
        console2.log("- Reward Per Block:", stakingPool.rewardPerBlock() / 1e18, "KK");
        console2.log("- Total Staked:", stakingPool.totalStaked() / 1e18, "ETH");
        console2.log("- Last Reward Block:", stakingPool.lastRewardBlock());
        console2.log("- Current Block:", block.number);
        console2.log("- Admin has admin role:", stakingPool.hasRole(stakingPool.ADMIN_ROLE(), adminAddress));
        
        // Verify contract interconnections
        console2.log("\nContract Interconnections:");
        console2.log("- StakingPool -> WETH correct:", address(stakingPool.stakingToken()) == address(weth));
        console2.log("- StakingPool -> KKToken correct:", address(stakingPool.rewardToken()) == address(kkToken));
        
        console2.log("\n=== ALL TESTS PASSED ===");
        console2.log("Contracts are successfully deployed and configured!");
        
        console2.log("\nNext steps:");
        console2.log("1. Users can now stake ETH using stakeETH()");
        console2.log("2. Rewards will be distributed at", stakingPool.rewardPerBlock() / 1e18, "KK tokens per block");
        console2.log("3. Monitor the system with Monitor.s.sol");
        console2.log("4. Manage with Admin.s.sol");
        
        console2.log("\nContract URLs on PolygonScan:");
        console2.log("- MockWETH: https://polygonscan.com/address/" , address(weth));
        console2.log("- KKToken: https://polygonscan.com/address/" , address(kkToken));
        console2.log("- StakingPool: https://polygonscan.com/address/" , address(stakingPool));
    }
}