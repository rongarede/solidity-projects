// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../test/mocks/MockWETH.sol";
import "../contracts/UniswapV2Router02.sol";

contract VerifyMockWETH is Script {
    function run() external view {
        // From contracts-addresses.json (updated addresses)
        address mockWETHAddress = 0x7Ff8501f89DBFde83ad5b46ce04a508403a28700;
        address routerAddress = 0xcEc76053fBa3fDB41570B816bc42d4DB7497bC72;
        
        MockWETH mockWETH = MockWETH(payable(mockWETHAddress));
        UniswapV2Router02 router = UniswapV2Router02(payable(routerAddress));
        
        console.log("=== MockWETH Integration Verification ===");
        console.log("MockWETH address:", address(mockWETH));
        console.log("Router address:", address(router));
        console.log("Router WETH address:", router.WETH());
        
        // Verify Router is configured with correct MockWETH
        bool routerCorrect = router.WETH() == address(mockWETH);
        console.log("Router WETH matches MockWETH:", routerCorrect);
        
        // Verify MockWETH contract properties
        console.log("MockWETH name:", mockWETH.name());
        console.log("MockWETH symbol:", mockWETH.symbol());
        console.log("MockWETH decimals:", mockWETH.decimals());
        console.log("MockWETH total supply:", mockWETH.totalSupply());
        
        // Verify Router factory connection
        console.log("Router factory address:", router.factory());
        
        console.log("\n=== Verification Results ===");
        if (routerCorrect) {
            console.log("SUCCESS: Router correctly configured with MockWETH");
            console.log("SUCCESS: MockWETH successfully replaces Base mainnet WETH");
            console.log("SUCCESS: System ready for testing without real ETH dependency");
        } else {
            console.log("ERROR: Router WETH configuration mismatch");
        }
    }
}