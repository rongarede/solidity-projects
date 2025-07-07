// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import "../src/BigBank.sol";
import "../src/Admin.sol";

contract DeployScript is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // 1. 部署 BigBank
        BigBank bigBank = new BigBank();
        console.log("BigBank deployed at:", address(bigBank));

        // 2. 部署 Admin
        Admin admin = new Admin();
        console.log("Admin deployed at:", address(admin));

        // 3. 将 BigBank 的 owner 转移给 Admin
        bigBank.transferOwnership(address(admin));
        console.log("BigBank ownership transferred to Admin");

        vm.stopBroadcast();
    }
}