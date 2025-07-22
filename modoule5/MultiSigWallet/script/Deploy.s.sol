// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/MultiSigWallet.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        vm.startBroadcast(deployerPrivateKey);
        
        // 配置多签钱包参数
        address[] memory owners = new address[](3);
        owners[0] = 0x1234567890123456789012345678901234567890; // 替换为实际地址
        owners[1] = 0x2345678901234567890123456789012345678901; // 替换为实际地址
        owners[2] = 0x3456789012345678901234567890123456789012; // 替换为实际地址
        
        uint256 threshold = 2;
        
        // 部署多签钱包
        MultiSigWallet wallet = new MultiSigWallet(owners, threshold);
        
        console.log("MultiSigWallet deployed at:", address(wallet));
        console.log("Contract owner:", wallet.owner());
        console.log("MultiSig owners:", owners.length);
        console.log("Threshold:", threshold);
        console.log("Uses OpenZeppelin ReentrancyGuard, Address utils, and Ownable");
        
        vm.stopBroadcast();
    }
}