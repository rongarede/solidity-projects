// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Script.sol";
import "../src/TestToken.sol";

contract DeployTestToken is Script {
    function run() external {
        // 从环境变量读取配置
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        string memory tokenName = vm.envString("TOKEN_NAME");
        string memory tokenSymbol = vm.envString("TOKEN_SYMBOL");
        uint8 tokenDecimals = uint8(vm.envUint("TOKEN_DECIMALS"));
        uint256 initialSupply = vm.envUint("INITIAL_SUPPLY");
        address initialOwner = vm.envAddress("INITIAL_OWNER");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 部署 TestToken 合约
        TestToken token = new TestToken(
            tokenName,
            tokenSymbol,
            tokenDecimals,
            initialSupply,
            initialOwner
        );
        
        vm.stopBroadcast();
        
        // 输出部署信息
        console.log("TestToken deployed to:", address(token));
        console.log("Token Name:", tokenName);
        console.log("Token Symbol:", tokenSymbol);
        console.log("Token Decimals:", tokenDecimals);
        console.log("Initial Supply:", initialSupply * 10**tokenDecimals);
        console.log("Initial Owner:", initialOwner);
        
        // 验证部署
        require(token.owner() == initialOwner, "Owner not set correctly");
        require(token.balanceOf(initialOwner) == initialSupply * 10**tokenDecimals, "Initial supply not minted correctly");
        
        console.log("✅ Deployment verification successful!");
    }
}