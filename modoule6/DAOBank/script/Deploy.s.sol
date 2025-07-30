// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Script, console} from "forge-std/Script.sol";
import {VotingToken} from "../src/contracts/VotingToken.sol";
import {Bank} from "../src/contracts/Bank.sol";
import {Gov} from "../src/contracts/Gov.sol";

/**
 * @title Deploy Script
 * @dev Deployment script for the complete DAO Bank system
 * Usage: forge script script/Deploy.s.sol --rpc-url <RPC_URL> --private-key <PRIVATE_KEY> --broadcast
 */
contract DeployScript is Script {
    
    // Deployment configuration
    struct DeploymentConfig {
        string tokenName;
        string tokenSymbol;
        address deployer;
        address[] initialTokenHolders;
        uint256[] initialTokenAmounts;
        uint256 initialBankDeposit;
    }

    VotingToken public token;
    Bank public bank;
    Gov public gov;

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== DAO BANK DEPLOYMENT ===");
        console.log("Deployer address:", deployer);
        console.log("Deployer balance:", deployer.balance / 10**18, "ETH");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy with configuration
        DeploymentConfig memory config = getDeploymentConfig(deployer);
        deploySystem(config);
        
        vm.stopBroadcast();
        
        // Log deployment addresses
        logDeployment();
        
        // Verify deployment
        verifyDeployment(config);
        
        console.log("=== DEPLOYMENT COMPLETED SUCCESSFULLY ===");
    }

    function deploySystem(DeploymentConfig memory config) internal {
        console.log("\n=== PHASE 1: DEPLOY VOTING TOKEN ===");
        
        // 1. Deploy VotingToken
        token = new VotingToken(
            config.tokenName,
            config.tokenSymbol,
            config.deployer
        );
        console.log("VotingToken deployed at:", address(token));
        console.log("Total supply:", token.totalSupply() / 10**18, "tokens");
        
        console.log("\n=== PHASE 2: DEPLOY BANK ===");
        
        // 2. Deploy Bank with deployer as initial admin
        bank = new Bank(config.deployer);
        console.log("Bank deployed at:", address(bank));
        console.log("Initial admin:", bank.owner());
        
        console.log("\n=== PHASE 3: DEPLOY GOVERNANCE ===");
        
        // 3. Deploy Gov with VotingToken and Bank addresses
        gov = new Gov(address(token), payable(address(bank)));
        console.log("Gov deployed at:", address(gov));
        console.log("Governance parameters:");
        console.log("  - Voting delay: 1 day");
        console.log("  - Voting period: 3 days");
        console.log("  - Execution delay: 2 days");
        console.log("  - Proposal threshold:", gov.getProposalThreshold() / 10**18, "tokens");
        console.log("  - Quorum:", gov.getQuorum() / 10**18, "tokens");
        
        console.log("\n=== PHASE 4: TRANSFER BANK OWNERSHIP TO DAO ===");
        
        // 4. Set Gov as Bank admin (transfer control to DAO)
        bank.changeAdmin(address(gov));
        console.log("Bank admin changed to Gov contract");
        console.log("New admin:", bank.owner());
        
        console.log("\n=== PHASE 5: DISTRIBUTE INITIAL TOKENS ===");
        
        // 5. Distribute initial tokens to stakeholders
        require(
            config.initialTokenHolders.length == config.initialTokenAmounts.length,
            "Token holders and amounts length mismatch"
        );
        
        uint256 totalDistributed = 0;
        for (uint i = 0; i < config.initialTokenHolders.length; i++) {
            if (config.initialTokenAmounts[i] > 0) {
                token.transfer(config.initialTokenHolders[i], config.initialTokenAmounts[i]);
                totalDistributed += config.initialTokenAmounts[i];
                console.log(
                    "Transferred", 
                    config.initialTokenAmounts[i] / 10**18, 
                    "tokens to", 
                    config.initialTokenHolders[i]
                );
            }
        }
        console.log("Total tokens distributed:", totalDistributed / 10**18);
        console.log("Tokens remaining with deployer:", token.balanceOf(config.deployer) / 10**18);
        
        console.log("\n=== PHASE 6: INITIAL BANK DEPOSIT ===");
        
        // 6. Make initial deposit to bank if specified
        if (config.initialBankDeposit > 0 && address(this).balance >= config.initialBankDeposit) {
            bank.deposit{value: config.initialBankDeposit}();
            console.log("Initial bank deposit:", config.initialBankDeposit / 10**18, "ETH");
        } else {
            console.log("No initial bank deposit made");
        }
    }

    function getDeploymentConfig(address deployer) internal pure returns (DeploymentConfig memory) {
        // Create arrays for initial token distribution
        address[] memory holders = new address[](4);
        uint256[] memory amounts = new uint256[](4);
        
        // Example distribution - customize as needed
        holders[0] = 0x1234567890123456789012345678901234567890; // Replace with actual addresses
        holders[1] = 0x2345678901234567890123456789012345678901;
        holders[2] = 0x3456789012345678901234567890123456789012;
        holders[3] = 0x4567890123456789012345678901234567890123;
        
        amounts[0] = 200_000 * 10**18; // 20%
        amounts[1] = 150_000 * 10**18; // 15%
        amounts[2] = 100_000 * 10**18; // 10%
        amounts[3] = 50_000 * 10**18;  // 5%
        // Deployer keeps 500_000 tokens (50%)
        
        return DeploymentConfig({
            tokenName: "DAO Bank Token",
            tokenSymbol: "DBT",
            deployer: deployer,
            initialTokenHolders: holders,
            initialTokenAmounts: amounts,
            initialBankDeposit: 0 // Set to desired amount, e.g., 10 ether
        });
    }

    function logDeployment() internal view {
        console.log("\n=== DEPLOYMENT SUMMARY ===");
        console.log("VotingToken:", address(token));
        console.log("Bank:", address(bank));
        console.log("Gov:", address(gov));
        console.log("\n=== CONTRACT VERIFICATION COMMANDS ===");
        console.log("Verify VotingToken:");
        console.log(string.concat("forge verify-contract ", vm.toString(address(token)), " src/contracts/VotingToken.sol:VotingToken --chain-id 1"));
        console.log("Verify Bank:");
        console.log(string.concat("forge verify-contract ", vm.toString(address(bank)), " src/contracts/Bank.sol:Bank --chain-id 1"));
        console.log("Verify Gov:");
        console.log(string.concat("forge verify-contract ", vm.toString(address(gov)), " src/contracts/Gov.sol:Gov --chain-id 1"));
    }

    function verifyDeployment(DeploymentConfig memory config) internal view {
        console.log("\n=== DEPLOYMENT VERIFICATION ===");
        
        // Verify VotingToken
        require(address(token) != address(0), "VotingToken not deployed");
        require(
            keccak256(bytes(token.name())) == keccak256(bytes(config.tokenName)),
            "VotingToken name mismatch"
        );
        require(
            keccak256(bytes(token.symbol())) == keccak256(bytes(config.tokenSymbol)),
            "VotingToken symbol mismatch"
        );
        require(token.totalSupply() == 1_000_000 * 10**18, "VotingToken total supply incorrect");
        console.log("VotingToken verification passed");
        
        // Verify Bank
        require(address(bank) != address(0), "Bank not deployed");
        require(bank.owner() == address(gov), "Bank admin not set to Gov");
        console.log("Bank verification passed");
        
        // Verify Gov
        require(address(gov) != address(0), "Gov not deployed");
        require(address(gov.votingToken()) == address(token), "Gov token reference incorrect");
        require(address(gov.bank()) == address(bank), "Gov bank reference incorrect");
        require(gov.getProposalThreshold() == 10_000 * 10**18, "Proposal threshold incorrect");
        require(gov.getQuorum() == 40_000 * 10**18, "Quorum incorrect");
        console.log("Gov verification passed");
        
        console.log("All contracts deployed and configured correctly");
    }
}

/**
 * @title Local Deployment Script
 * @dev Script for local testing and development
 */
contract LocalDeployScript is Script {
    
    function run() external {
        address deployer = msg.sender;
        
        console.log("=== LOCAL DAO BANK DEPLOYMENT ===");
        console.log("Deployer:", deployer);
        
        // Deploy contracts
        VotingToken token = new VotingToken("DAO Bank Token", "DBT", deployer);
        Bank bank = new Bank(deployer);
        Gov gov = new Gov(address(token), payable(address(bank)));
        
        // Configure system
        bank.changeAdmin(address(gov));
        
        // Create test accounts and distribute tokens
        address alice = makeAddr("alice");
        address bob = makeAddr("bob");
        address charlie = makeAddr("charlie");
        
        token.transfer(alice, 200_000 * 10**18);
        token.transfer(bob, 150_000 * 10**18);
        token.transfer(charlie, 100_000 * 10**18);
        
        console.log("Contracts deployed:");
        console.log("  Token:", address(token));
        console.log("  Bank:", address(bank));
        console.log("  Gov:", address(gov));
        console.log("Test accounts created:");
        console.log("  Alice:", alice, "- 200k tokens");
        console.log("  Bob:", bob, "- 150k tokens");
        console.log("  Charlie:", charlie, "- 100k tokens");
    }
}