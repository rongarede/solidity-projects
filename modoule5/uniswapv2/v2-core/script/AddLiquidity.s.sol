// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function mint(address to, uint256 amount) external;
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Pair {
    function token0() external view returns (address);
    function token1() external view returns (address);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function mint(address to) external returns (uint256 liquidity);
}

contract AddLiquidityScript is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Add Liquidity to Pair ===");
        console.log("Deployer:", deployer);
        
        address tokenA = 0xd94b67a5e56696B57908c571eD1E5A40Ce3f64F3;
        address tokenB = 0x731495EAb495076B86CA562eDa51244F20A25CF5;
        address pairAddr = 0x27FD6cBE8d206047D695e966D54529b951848baF;
        
        vm.startBroadcast(deployerPrivateKey);
        
        IERC20 tokenAContract = IERC20(tokenA);
        IERC20 tokenBContract = IERC20(tokenB);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        
        // Check current balances
        uint256 balanceA = tokenAContract.balanceOf(deployer);
        uint256 balanceB = tokenBContract.balanceOf(deployer);
        console.log("TokenA Balance:", balanceA);
        console.log("TokenB Balance:", balanceB);
        
        // If no tokens, mint some
        if (balanceA == 0) {
            console.log("Minting TokenA...");
            tokenAContract.mint(deployer, 1000 * 1e18);
        }
        
        if (balanceB == 0) {
            console.log("Minting TokenB...");
            tokenBContract.mint(deployer, 1000 * 1e18);
        }
        
        // Add liquidity (send tokens to pair and call mint)
        uint256 amountA = 100 * 1e18; // 100 tokens
        uint256 amountB = 100 * 1e18; // 100 tokens
        
        console.log("Adding liquidity...");
        console.log("Amount A:", amountA);
        console.log("Amount B:", amountB);
        
        // Transfer tokens to pair
        tokenAContract.transfer(pairAddr, amountA);
        tokenBContract.transfer(pairAddr, amountB);
        
        // Call mint to create LP tokens
        uint256 liquidity = pair.mint(deployer);
        console.log("LP Tokens Minted:", liquidity);
        
        // Check reserves after adding liquidity
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        console.log("Final Reserve0:", reserve0);
        console.log("Final Reserve1:", reserve1);
        
        vm.stopBroadcast();
        
        console.log("[OK] Liquidity added successfully!");
    }
}