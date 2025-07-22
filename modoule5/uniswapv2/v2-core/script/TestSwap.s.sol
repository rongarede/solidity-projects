// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "forge-std/console.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function transfer(address to, uint256 amount) external returns (bool);
    function approve(address spender, uint256 amount) external returns (bool);
}

interface IUniswapV2Pair {
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
    function swap(uint256 amount0Out, uint256 amount1Out, address to, bytes calldata data) external;
    function token0() external view returns (address);
    function token1() external view returns (address);
}

contract TestSwapScript is Script {
    
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("=== Test Token Swap ===");
        console.log("Swapper:", deployer);
        
        address tokenA = 0xd94b67a5e56696B57908c571eD1E5A40Ce3f64F3;
        address tokenB = 0x731495EAb495076B86CA562eDa51244F20A25CF5;
        address pairAddr = 0x27FD6cBE8d206047D695e966D54529b951848baF;
        
        IERC20 tokenAContract = IERC20(tokenA);
        IERC20 tokenBContract = IERC20(tokenB);
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddr);
        
        vm.startBroadcast(deployerPrivateKey);
        
        // Check initial balances
        uint256 initialBalanceA = tokenAContract.balanceOf(deployer);
        uint256 initialBalanceB = tokenBContract.balanceOf(deployer);
        console.log("Initial TokenA Balance:", initialBalanceA);
        console.log("Initial TokenB Balance:", initialBalanceB);
        
        // Get reserves
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        console.log("Reserve0 (TokenB):", reserve0);
        console.log("Reserve1 (TokenA):", reserve1);
        
        // Swap 1 TokenA for TokenB
        uint256 amountIn = 1 * 1e18; // 1 token
        uint256 amountOut = getAmountOut(amountIn, reserve1, reserve0); // TokenA -> TokenB
        
        console.log("Swapping TokenA for TokenB");
        console.log("Amount In:", amountIn);
        console.log("Amount Out:", amountOut);
        
        // Transfer TokenA to pair
        tokenAContract.transfer(pairAddr, amountIn);
        
        // Perform swap (amount0Out=amountOut for TokenB, amount1Out=0)
        pair.swap(amountOut, 0, deployer, "");
        
        // Check final balances
        uint256 finalBalanceA = tokenAContract.balanceOf(deployer);
        uint256 finalBalanceB = tokenBContract.balanceOf(deployer);
        console.log("Final TokenA Balance:", finalBalanceA);
        console.log("Final TokenB Balance:", finalBalanceB);
        
        console.log("TokenA Change:", int256(finalBalanceA) - int256(initialBalanceA));
        console.log("TokenB Change:", int256(finalBalanceB) - int256(initialBalanceB));
        
        vm.stopBroadcast();
        
        console.log("[OK] Swap completed successfully!");
    }
    
    // Uniswap V2 formula: amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
    function getAmountOut(uint256 amountIn, uint256 reserveIn, uint256 reserveOut) public pure returns (uint256) {
        require(amountIn > 0, "Invalid input amount");
        require(reserveIn > 0 && reserveOut > 0, "Invalid reserves");
        
        uint256 amountInWithFee = amountIn * 997;
        uint256 numerator = amountInWithFee * reserveOut;
        uint256 denominator = reserveIn * 1000 + amountInWithFee;
        return numerator / denominator;
    }
}