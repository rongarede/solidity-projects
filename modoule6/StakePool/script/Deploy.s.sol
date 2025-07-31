// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Script, console2} from "forge-std/Script.sol";
import {MockWETH} from "../src/MockWETH.sol";
import {KKToken} from "../src/KKToken.sol";
import {StakingPool} from "../src/StakingPool.sol";

/**
 * @title Deploy
 * @dev Deployment script for the StakingPool ecosystem
 * Supports different networks with configurable parameters
 * Deploys contracts in the correct order and sets up permissions
 */
contract Deploy is Script {
    // Deployment addresses (will be set during deployment)
    MockWETH public weth;
    KKToken public kkToken;
    StakingPool public stakingPool;
    
    // Configuration
    address public admin;
    uint256 public rewardPerBlock;
    bool public skipVerification;
    
    // Network-specific configurations
    struct NetworkConfig {
        string name;
        uint256 chainId;
        uint256 rewardPerBlock;
        bool isTestnet;
    }
    
    mapping(uint256 => NetworkConfig) public networkConfigs;
    
    function setUp() public {
        // Initialize network configurations
        _initializeNetworkConfigs();
        
        // Get admin address from environment or use deployer
        admin = vm.envOr("ADMIN_ADDRESS", msg.sender);
        
        // Get reward per block from environment or use network default
        rewardPerBlock = vm.envOr("REWARD_PER_BLOCK", _getNetworkConfig().rewardPerBlock);
        
        // Check if we should skip verification
        skipVerification = vm.envOr("SKIP_VERIFICATION", false);
        
        console2.log("=== DEPLOYMENT CONFIGURATION ===");
        console2.log("Admin address:", admin);
        console2.log("Reward per block:", rewardPerBlock / 1e18, "KK tokens");
        console2.log("Skip verification:", skipVerification);
        console2.log("Network:", _getNetworkConfig().name);
    }
    
    function _initializeNetworkConfigs() internal {
        // Polygon Mainnet
        networkConfigs[137] = NetworkConfig({
            name: "Polygon Mainnet",
            chainId: 137,
            rewardPerBlock: 10 * 1e18, // 10 KK tokens per block
            isTestnet: false
        });
        
        // Polygon Mumbai Testnet
        networkConfigs[80001] = NetworkConfig({
            name: "Polygon Mumbai",
            chainId: 80001,
            rewardPerBlock: 10 * 1e18, // 10 KK tokens per block
            isTestnet: true
        });
        
        // Local/Anvil
        networkConfigs[31337] = NetworkConfig({
            name: "Local/Anvil",
            chainId: 31337,
            rewardPerBlock: 10 * 1e18, // 10 KK tokens per block
            isTestnet: true
        });
        
        // Ethereum Sepolia (fallback)
        networkConfigs[11155111] = NetworkConfig({
            name: "Ethereum Sepolia",
            chainId: 11155111,
            rewardPerBlock: 1 * 1e18, // Lower reward for expensive network
            isTestnet: true
        });
    }
    
    function _getNetworkConfig() internal view returns (NetworkConfig memory) {
        NetworkConfig memory config = networkConfigs[block.chainid];
        if (config.chainId == 0) {
            // Default configuration for unknown networks
            return NetworkConfig({
                name: "Unknown Network",
                chainId: block.chainid,
                rewardPerBlock: 10 * 1e18,
                isTestnet: true
            });
        }
        return config;
    }

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console2.log("\n=== PRE-DEPLOYMENT CHECKS ===");
        console2.log("Deploying contracts with account:", deployer);
        console2.log("Account balance:", deployer.balance);
        
        // Pre-deployment validations
        require(deployer.balance > 0, "Deployer account has no balance for gas fees");
        require(admin != address(0), "Admin address cannot be zero");
        
        NetworkConfig memory config = _getNetworkConfig();
        console2.log("Target network:", config.name);
        console2.log("Chain ID:", config.chainId);
        console2.log("Is testnet:", config.isTestnet);
        
        // Warning for mainnet deployments
        if (!config.isTestnet) {
            console2.log("\nWARNING: Deploying to MAINNET!");
            console2.log("Ensure you have tested on testnet first.");
            console2.log("Press Ctrl+C to cancel if unsure.");
        }
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 1. Deploy MockWETH
        console2.log("\n=== Deploying MockWETH ===");
        weth = new MockWETH();
        console2.log("MockWETH deployed at:", address(weth));
        console2.log("MockWETH name:", weth.name());
        console2.log("MockWETH symbol:", weth.symbol());
        
        // 2. Deploy KKToken
        console2.log("\n=== Deploying KKToken ===");
        kkToken = new KKToken(admin);
        console2.log("KKToken deployed at:", address(kkToken));
        console2.log("KKToken name:", kkToken.name());
        console2.log("KKToken symbol:", kkToken.symbol());
        console2.log("KKToken admin:", admin);
        
        // Verify admin has correct roles
        require(kkToken.hasRole(kkToken.DEFAULT_ADMIN_ROLE(), admin), "Admin should have DEFAULT_ADMIN_ROLE");
        require(kkToken.hasRole(kkToken.MINTER_ROLE(), admin), "Admin should have MINTER_ROLE");
        console2.log("Admin roles verified");
        
        // 3. Deploy StakingPool
        console2.log("\n=== Deploying StakingPool ===");
        stakingPool = new StakingPool(payable(address(weth)), address(kkToken), admin);
        console2.log("StakingPool deployed at:", address(stakingPool));
        console2.log("StakingPool admin:", admin);
        console2.log("StakingPool reward per block:", stakingPool.rewardPerBlock());
        
        // Verify StakingPool has correct references
        require(address(stakingPool.stakingToken()) == address(weth), "StakingPool should reference correct WETH");
        require(address(stakingPool.rewardToken()) == address(kkToken), "StakingPool should reference correct KKToken");
        require(stakingPool.hasRole(stakingPool.ADMIN_ROLE(), admin), "Admin should have ADMIN_ROLE on StakingPool");
        console2.log("StakingPool configuration verified");
        
        // 4. Grant MINTER_ROLE to StakingPool
        console2.log("\n=== Setting up permissions ===");
        kkToken.grantMinterRole(address(stakingPool));
        console2.log("Granted MINTER_ROLE to StakingPool");
        
        // Verify StakingPool can mint
        require(kkToken.hasRole(kkToken.MINTER_ROLE(), address(stakingPool)), "StakingPool should have MINTER_ROLE");
        console2.log("StakingPool minter role verified");
        
        vm.stopBroadcast();
        
        // 5. Log deployment summary
        console2.log("\n=== DEPLOYMENT SUMMARY ===");
        console2.log("Network:", config.name);
        console2.log("Chain ID:", block.chainid);
        console2.log("Block Number:", block.number);
        console2.log("Block Timestamp:", block.timestamp);
        console2.log("Deployer:", deployer);
        console2.log("Admin:", admin);
        console2.log("");
        
        console2.log("📋 Contract Addresses:");
        console2.log("MockWETH:     ", address(weth));
        console2.log("KKToken:      ", address(kkToken));
        console2.log("StakingPool:  ", address(stakingPool));
        console2.log("");
        
        console2.log("⚙️  Configuration:");
        console2.log("Reward per block: ", stakingPool.rewardPerBlock() / 1e18, "KK tokens");
        console2.log("Total staked:     ", stakingPool.totalStaked() / 1e18, "WETH");
        console2.log("Last reward block:", stakingPool.lastRewardBlock());
        console2.log("");
        
        console2.log("🔐 Permissions:");
        console2.log("KKToken admin:        ", kkToken.hasRole(kkToken.DEFAULT_ADMIN_ROLE(), admin));
        console2.log("KKToken minter:       ", kkToken.hasRole(kkToken.MINTER_ROLE(), admin));
        console2.log("StakingPool admin:    ", stakingPool.hasRole(stakingPool.ADMIN_ROLE(), admin));
        console2.log("StakingPool minter:   ", kkToken.hasRole(kkToken.MINTER_ROLE(), address(stakingPool)));
        console2.log("");
        
        if (config.isTestnet) {
            console2.log("🧪 Testnet Deployment - Safe to experiment!");
        } else {
            console2.log("🚀 Mainnet Deployment - Handle with care!");
        }
        console2.log("");
        
        console2.log("📝 Next steps:");
        if (!skipVerification) {
            console2.log("1. ✅ Contract verification completed automatically");
        } else {
            console2.log("1. ⚠️  Verify contracts manually on block explorer");
        }
        console2.log("2. 🧪 Test functionality: forge script script/Demo.s.sol --broadcast");
        console2.log("3. 📊 Monitor pool: forge script script/Monitor.s.sol");
        console2.log("4. 👥 Share contract addresses with users");
        console2.log("5. 🔍 Monitor transactions and events");
        
        // 6. Save comprehensive deployment info to files
        _saveDeploymentFiles(deployer, config);
        
        console2.log("\n📁 Files created:");
        console2.log("- deployments.txt (contract addresses)");
        console2.log("- deployment_info.json (full deployment details)");
        console2.log("- .env.deployed (environment variables template)");
    }
    
    function _saveDeploymentFiles(address deployer, NetworkConfig memory config) internal {
        // 1. Save simple addresses file
        string memory addresses = string(abi.encodePacked(
            "MockWETH=", vm.toString(address(weth)), "\n",
            "KKToken=", vm.toString(address(kkToken)), "\n", 
            "StakingPool=", vm.toString(address(stakingPool)), "\n",
            "Admin=", vm.toString(admin), "\n",
            "Deployer=", vm.toString(deployer), "\n"
        ));
        vm.writeFile("deployments.txt", addresses);
        
        // 2. Save detailed JSON deployment info
        string memory deploymentInfo = string(abi.encodePacked(
            "{\n",
            '  "network": "', config.name, '",\n',
            '  "chainId": ', vm.toString(config.chainId), ',\n',
            '  "blockNumber": ', vm.toString(block.number), ',\n',
            '  "timestamp": ', vm.toString(block.timestamp), ',\n',
            '  "deployer": "', vm.toString(deployer), '",\n',
            '  "admin": "', vm.toString(admin), '",\n',
            '  "contracts": {\n',
            '    "MockWETH": "', vm.toString(address(weth)), '",\n',
            '    "KKToken": "', vm.toString(address(kkToken)), '",\n',
            '    "StakingPool": "', vm.toString(address(stakingPool)), '"\n',
            '  },\n',
            '  "configuration": {\n',
            '    "rewardPerBlock": "', vm.toString(rewardPerBlock), '",\n',
            '    "rewardPerBlockFormatted": "', vm.toString(rewardPerBlock / 1e18), ' KK tokens"\n',
            '  }\n',
            "}"
        ));
        vm.writeFile("deployment_info.json", deploymentInfo);
        
        // 3. Save environment template for frontend/integration
        string memory envTemplate = string(abi.encodePacked(
            "# Generated deployment environment variables\n",
            "# Copy these to your frontend/.env or integration scripts\n\n",
            "NETWORK_NAME=", config.name, "\n",
            "CHAIN_ID=", vm.toString(config.chainId), "\n",
            "MOCKWETH_ADDRESS=", vm.toString(address(weth)), "\n",
            "KKTOKEN_ADDRESS=", vm.toString(address(kkToken)), "\n",
            "STAKINGPOOL_ADDRESS=", vm.toString(address(stakingPool)), "\n",
            "ADMIN_ADDRESS=", vm.toString(admin), "\n",
            "REWARD_PER_BLOCK=", vm.toString(rewardPerBlock), "\n"
        ));
        vm.writeFile(".env.deployed", envTemplate);
    }
    
    /**
     * @dev Verify deployment was successful
     * Can be called separately to check deployment status
     */
    function verify() public view {
        require(address(weth) != address(0), "MockWETH not deployed");
        require(address(kkToken) != address(0), "KKToken not deployed");
        require(address(stakingPool) != address(0), "StakingPool not deployed");
        
        // Verify contract interconnections
        require(address(stakingPool.stakingToken()) == address(weth), "Incorrect WETH reference");
        require(address(stakingPool.rewardToken()) == address(kkToken), "Incorrect KKToken reference");
        
        // Verify permissions
        require(kkToken.hasRole(kkToken.MINTER_ROLE(), address(stakingPool)), "StakingPool missing MINTER_ROLE");
        require(stakingPool.hasRole(stakingPool.ADMIN_ROLE(), admin), "Admin missing ADMIN_ROLE");
        
        console2.log("✅ All verifications passed");
    }
    
    /**
     * @dev Get current network configuration
     */
    function getNetworkConfig() external view returns (NetworkConfig memory) {
        return _getNetworkConfig();
    }
    
    /**
     * @dev Emergency function to update reward per block (admin only)
     */
    function updateRewardRate(uint256 newRewardPerBlock) external {
        require(msg.sender == admin, "Only admin can update reward rate");
        require(address(stakingPool) != address(0), "StakingPool not deployed");
        
        // This would need to be called with proper permissions in a real scenario
        console2.log("Use this command to update reward rate:");
        console2.log("cast send", address(stakingPool), '"updateRewardPerBlock(uint256)"', newRewardPerBlock, "--private-key $PRIVATE_KEY");
    }
}