// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {KKToken} from "../src/KKToken.sol";
import {StakingPool} from "../src/StakingPool.sol";

/**
 * @title SimpleDeploy
 * @dev Simple deployment script without Unicode characters
 */
contract SimpleDeploy is Script {
    MockWETH public weth;
    KKToken public kkToken;
    StakingPool public stakingPool;
    
    address public admin;
    uint256 public constant REWARD_PER_BLOCK = 10 * 1e18;

    function setUp() public {
        admin = vm.envOr("ADMIN_ADDRESS", msg.sender);
        console2.log("=== DEPLOYMENT CONFIGURATION ===");
        console2.log("Admin address:", admin);
        console2.log("Reward per block:", REWARD_PER_BLOCK / 1e18, "KK tokens");
    }

    function run() public {
        string memory privateKeyStr = vm.envString("PRIVATE_KEY");
        uint256 deployerPrivateKey = vm.parseUint(string.concat("0x", privateKeyStr));
        address deployer = vm.addr(deployerPrivateKey);
        
        // If admin is not set in env, use deployer as admin
        if (admin == msg.sender) {
            admin = deployer;
        }
        
        console2.log("\n=== PRE-DEPLOYMENT CHECKS ===");
        console2.log("Deploying contracts with account:", deployer);
        console2.log("Admin will be:", admin);
        console2.log("Account balance:", deployer.balance);
        console2.log("Chain ID:", block.chainid);
        
        require(deployer.balance > 0, "Deployer account has no balance");
        require(admin != address(0), "Admin address cannot be zero");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy MockWETH
        console2.log("\n=== Deploying MockWETH ===");
        weth = new MockWETH();
        console2.log("MockWETH deployed at:", address(weth));
        
        // 2. Deploy KKToken
        console2.log("\n=== Deploying KKToken ===");
        kkToken = new KKToken(admin);
        console2.log("KKToken deployed at:", address(kkToken));
        
        // Verify admin roles
        require(kkToken.hasRole(kkToken.DEFAULT_ADMIN_ROLE(), admin), "Admin missing DEFAULT_ADMIN_ROLE");
        require(kkToken.hasRole(kkToken.MINTER_ROLE(), admin), "Admin missing MINTER_ROLE");
        console2.log("Admin roles verified");
        
        // 3. Deploy StakingPool
        console2.log("\n=== Deploying StakingPool ===");
        stakingPool = new StakingPool(payable(address(weth)), address(kkToken), admin);
        console2.log("StakingPool deployed at:", address(stakingPool));
        
        // Verify StakingPool configuration
        require(address(stakingPool.stakingToken()) == address(weth), "Wrong WETH reference");
        require(address(stakingPool.rewardToken()) == address(kkToken), "Wrong KKToken reference");
        require(stakingPool.hasRole(stakingPool.ADMIN_ROLE(), admin), "Admin missing ADMIN_ROLE");
        console2.log("StakingPool configuration verified");
        
        // 4. Grant MINTER_ROLE to StakingPool
        console2.log("\n=== Setting up permissions ===");
        kkToken.grantMinterRole(address(stakingPool));
        console2.log("Granted MINTER_ROLE to StakingPool");
        
        // Verify final permissions
        require(kkToken.hasRole(kkToken.MINTER_ROLE(), address(stakingPool)), "StakingPool missing MINTER_ROLE");
        console2.log("All permissions verified");
        
        vm.stopBroadcast();
        
        // 5. Deployment Summary
        console2.log("\n=== DEPLOYMENT SUMMARY ===");
        console2.log("Network Chain ID:", block.chainid);
        console2.log("Block Number:", block.number);
        console2.log("Deployer:", deployer);
        console2.log("Admin:", admin);
        console2.log("");
        console2.log("Contract Addresses:");
        console2.log("MockWETH:     ", address(weth));
        console2.log("KKToken:      ", address(kkToken));
        console2.log("StakingPool:  ", address(stakingPool));
        console2.log("");
        console2.log("Configuration:");
        console2.log("Reward per block: ", stakingPool.rewardPerBlock() / 1e18, "KK tokens");
        console2.log("");
        console2.log("Next steps:");
        console2.log("1. Test with Demo script");
        console2.log("2. Monitor with Monitor script");
        console2.log("3. Manage with Admin script");
        
        // 6. Save addresses to file
        string memory addresses = string(abi.encodePacked(
            "MockWETH=", vm.toString(address(weth)), "\n",
            "KKToken=", vm.toString(address(kkToken)), "\n", 
            "StakingPool=", vm.toString(address(stakingPool)), "\n",
            "Admin=", vm.toString(admin), "\n",
            "Deployer=", vm.toString(deployer), "\n"
        ));
        
        vm.writeFile("deployments.txt", addresses);
        console2.log("Contract addresses saved to deployments.txt");
        
        // 7. Save environment variables
        string memory envDeployed = string(abi.encodePacked(
            "# Deployed contract addresses - add to your .env\n",
            "MOCKWETH_ADDRESS=", vm.toString(address(weth)), "\n",
            "KKTOKEN_ADDRESS=", vm.toString(address(kkToken)), "\n",
            "STAKINGPOOL_ADDRESS=", vm.toString(address(stakingPool)), "\n",
            "ADMIN_ADDRESS=", vm.toString(admin), "\n"
        ));
        
        vm.writeFile(".env.deployed", envDeployed);
        console2.log("Environment variables saved to .env.deployed");
        
        console2.log("\n=== DEPLOYMENT COMPLETED SUCCESSFULLY ===");
    }
}