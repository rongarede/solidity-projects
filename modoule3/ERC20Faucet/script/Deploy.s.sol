// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/TestToken.sol";
import "../src/TokenFaucet.sol";

contract DeployScript is Script {
    function run() external {
        vm.startBroadcast();
        
        // 部署 TestToken
        TestToken token = new TestToken();
        console.log("TestToken deployed at:", address(token));
        
        // 部署 TokenFaucet
        // 参数：代币地址，每次领取100个代币，冷却时间24小时
        TokenFaucet faucet = new TokenFaucet(
            address(token),
            100,  // 100 TST per request
            24 * 60 * 60  // 24 hours cooldown
        );
        console.log("TokenFaucet deployed at:", address(faucet));
        
        // 向水龙头转入10,000个代币
        uint256 faucetFunding = 10_000 * 10**18;
        token.transfer(address(faucet), faucetFunding);
        console.log("Transferred", faucetFunding / 10**18, "TST to faucet");
        
        console.log("Deployment completed!");
        console.log("Token total supply:", token.totalSupply() / 10**18);
        console.log("Faucet balance:", faucet.getFaucetBalance() / 10**18);
        
        vm.stopBroadcast();
    }
}