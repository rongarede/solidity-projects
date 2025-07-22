// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with the account:", deployer);
        console.log("Account balance:", deployer.balance);

        vm.startBroadcast(deployerPrivateKey);

        // 部署 MemeFactory (会自动部署 MemeToken 实现合约)
        MemeFactory factory = new MemeFactory();
        
        vm.stopBroadcast();

        console.log("MemeFactory deployed to:", address(factory));
        console.log("MemeToken implementation deployed to:", factory.implementation());
        
        // 保存部署地址到文件
        string memory addresses = string(abi.encodePacked(
            "FACTORY_ADDRESS=", vm.toString(address(factory)), "\n",
            "IMPLEMENTATION_ADDRESS=", vm.toString(factory.implementation()), "\n"
        ));
        vm.writeFile("deployments.env", addresses);
        
        console.log("Deployment addresses saved to deployments.env");
    }
}