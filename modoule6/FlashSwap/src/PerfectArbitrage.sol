// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "forge-std/console.sol";

/**
 * @title IUniswapV2Pair
 * @dev Uniswap V2 交易对合约交互接口
 */
interface IUniswapV2Pair {
    /// @notice 在交易对中执行代币交换
    function swap(uint amount0Out, uint amount1Out, address to, bytes calldata data) external;
    /// @notice 获取交易对中token0的地址
    function token0() external view returns (address);
    /// @notice 获取交易对中token1的地址
    function token1() external view returns (address);
    /// @notice 获取交易对中两种代币的当前储备量
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

/**
 * @title IUniswapV2Callee
 * @dev 接收 Uniswap V2 闪电贷回调的接口
 */
interface IUniswapV2Callee {
    /// @notice 闪电交换期间由 Uniswap V2 交易对调用的回调函数
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external;
}

/**
 * @title PerfectArbitrage
 * @dev 使用 Uniswap V2 闪电交换执行三角套利的合约
 * @notice 此合约实现 A→C→B→A 套利策略以避免重入锁定
 * 
 * 核心功能:
 * - 从 PairAB 闪电借贷 TokenA
 * - 通过 PairAC 将 A→C (避免重入)
 * - 通过 PairBC 将 C→B (利用价格差异)
 * - 通过替代路径 B→C→A 还款 (避免重入)
 * - 自动提取利润给合约所有者
 * 
 * 策略流程:
 * 1. 使用闪电交换从 PairAB 借入 TokenA
 * 2. 直接使用 PairAC 将 A→C
 * 3. 使用 PairBC 将 C→B (从2:1价格比率中获利)
 * 4. 使用替代路径 B→C→A 偿还贷款
 * 5. 提取剩余代币作为利润
 */
contract PerfectArbitrage is IUniswapV2Callee, Ownable {
    using SafeERC20 for IERC20;
    
    /// @notice TokenA的地址 (套利基础代币)
    address public tokenA;
    /// @notice TokenB的地址 (中间代币)
    address public tokenB; 
    /// @notice TokenC的地址 (目标代币)
    address public tokenC;
    /// @notice A/B交易对的地址
    address public pairAB;
    /// @notice B/C交易对的地址
    address public pairBC;
    /// @notice A/C交易对的地址
    address public pairAC;
    
    /**
     * @notice 套利操作成功执行时触发的事件
     * @param amountBorrowed 通过闪电交换借入的TokenA数量
     * @param profit 产生的总利润 (简化计算)
     * @param executor 发起套利的地址
     */
    event ArbitrageExecuted(
        uint256 amountBorrowed,
        uint256 profit,
        address indexed executor
    );
    
    /**
     * @notice 构造函数，初始化合约参数
     * @param _tokenA TokenA合约地址
     * @param _tokenB TokenB合约地址
     * @param _tokenC TokenC合约地址
     * @param _pairAB A/B交易对地址
     * @param _pairBC B/C交易对地址
     * @param _pairAC A/C交易对地址
     */
    constructor(
        address _tokenA,
        address _tokenB,
        address _tokenC,
        address _pairAB,
        address _pairBC,
        address _pairAC
    ) Ownable(msg.sender) {
        tokenA = _tokenA;
        tokenB = _tokenB;
        tokenC = _tokenC;
        pairAB = _pairAB;
        pairBC = _pairBC;
        pairAC = _pairAC;
    }
    
    /**
     * @notice 执行完美套利策略: 从AB借入A → A→C→B→A
     * @param amountToBorrow 要借入的TokenA数量
     * @dev 只有合约所有者可以调用此函数
     */
    function executePerfectArbitrage(uint256 amountToBorrow) external onlyOwner {
        require(amountToBorrow > 0, "Amount must be greater than 0");
        
        IUniswapV2Pair pair = IUniswapV2Pair(pairAB);
        address token0 = pair.token0();
        address token1 = pair.token1();
        
        uint256 amount0Out;
        uint256 amount1Out;
        
        // 确定TokenA在PairAB中是token0还是token1
        if (tokenA == token0) {
            amount0Out = amountToBorrow;
            amount1Out = 0;
        } else {
            amount0Out = 0;
            amount1Out = amountToBorrow;
        }
        
        // 编码回调数据
        bytes memory data = abi.encode(amountToBorrow, msg.sender);
        // 发起闪电交换
        pair.swap(amount0Out, amount1Out, address(this), data);
    }
    
    /**
     * @notice Uniswap V2 闪电交换回调函数
     * @param sender 发起交换的地址
     * @param amount0 借出的token0数量
     * @param amount1 借出的token1数量
     * @param data 回调数据
     * @dev 此函数由交易对合约在闪电交换期间调用
     */
    function uniswapV2Call(address sender, uint amount0, uint amount1, bytes calldata data) external override {
        require(msg.sender == pairAB, "Unauthorized caller");
        require(sender == address(this), "Unauthorized sender");
        
        // 解码回调数据
        (uint256 amountBorrowed, address executor) = abi.decode(data, (uint256, address));
        
        // 执行完美套利策略: A → C → B → A
        executePerfectStrategy(amountBorrowed, executor);
    }
    
    /**
     * @notice 执行完美套利策略的内部函数
     * @param amountBorrowed 借入的TokenA数量
     * @param executor 发起套利的地址
     * @dev 实现A→C→B→A的完整交易流程
     */
    function executePerfectStrategy(uint256 amountBorrowed, address executor) internal {
        console.log("=== PERFECT ARBITRAGE EXECUTION ===");
        console.log("Step 1: Borrowed TokenA:", amountBorrowed);
        
        uint256 initialTokenABalance = IERC20(tokenA).balanceOf(address(this));
        console.log("Contract TokenA balance:", initialTokenABalance);
        
        // 步顤2: 通过PairAC将A→C (直接交换，无需路由)
        console.log("Step 2: Converting A to C via PairAC...");
        uint256 tokenCReceived = swapAtoC(amountBorrowed);
        console.log("Received TokenC:", tokenCReceived);
        
        // 步顤3: 通过PairBC将C→B (直接交换，无需路由)
        console.log("Step 3: Converting C to B via PairBC...");
        uint256 tokenBReceived = swapCtoB(tokenCReceived);
        console.log("Received TokenB:", tokenBReceived);
        
        // 步顤4: 通过替代路径将B转换回A用于还款 (B→C→A)
        console.log("Step 4: Converting B back to A for repayment...");
        uint256 fee = (amountBorrowed * 3) / 997 + 1; // Uniswap 0.3% 手续费
        uint256 amountToRepay = amountBorrowed + fee;
        console.log("Need to repay TokenA:", amountToRepay);
        console.log("Fee amount:", fee);
        
        // Use alternative path: B→C via PairBC, then C→A via PairAC to avoid reentrancy
        uint256 tokenAFromAlternativePath = swapBtoAViaC(amountToRepay);
        console.log("Converted for repayment - TokenA:", tokenAFromAlternativePath);
        
        // Verify we have enough to repay
        require(IERC20(tokenA).balanceOf(address(this)) >= amountToRepay, "Insufficient TokenA for repayment");
        
        // Repay the flashloan
        IERC20(tokenA).safeTransfer(pairAB, amountToRepay);
        console.log("Repaid TokenA to PairAB:", amountToRepay);
        
        // Calculate profit and transfer to executor
        uint256 remainingTokenB = IERC20(tokenB).balanceOf(address(this));
        uint256 remainingTokenA = IERC20(tokenA).balanceOf(address(this));
        
        console.log("=== PROFIT CALCULATION ===");
        console.log("Remaining TokenB:", remainingTokenB);
        console.log("Remaining TokenA:", remainingTokenA);
        
        // Transfer all remaining tokens as profit
        if (remainingTokenB > 0) {
            IERC20(tokenB).safeTransfer(executor, remainingTokenB);
            console.log("Transferred TokenB profit:", remainingTokenB);
        }
        
        if (remainingTokenA > 0) {
            IERC20(tokenA).safeTransfer(executor, remainingTokenA);
            console.log("Transferred TokenA profit:", remainingTokenA);
        }
        
        uint256 totalProfit = remainingTokenA + remainingTokenB; // Simplified calculation
        emit ArbitrageExecuted(amountBorrowed, totalProfit, executor);
        
        console.log("=== ARBITRAGE COMPLETED SUCCESSFULLY ===");
    }
    
    /**
     * @notice 使用PairAC直接交换A→C
     * @param amountA 要交换的TokenA数量
     * @return 获得的TokenC数量
     * @dev 使用Uniswap V2常数乘积公式计算输出量
     */
    function swapAtoC(uint256 amountA) internal returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAC);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        address token0 = pair.token0();
        uint256 amountOut;
        
        if (token0 == tokenA) {
            // A是token0，C是token1
            // Uniswap公式: amountOut = (amountIn * 997 * reserveOut) / (reserveIn * 1000 + amountIn * 997)
            uint256 amountInWithFee = amountA * 997; // 考虑0.3%手续费
            uint256 numerator = amountInWithFee * uint256(reserve1);
            uint256 denominator = uint256(reserve0) * 1000 + amountInWithFee;
            amountOut = numerator / denominator;
            IERC20(tokenA).safeTransfer(address(pair), amountA);
            pair.swap(0, amountOut, address(this), "");
        } else {
            // A是token1，C是token0
            uint256 amountInWithFee = amountA * 997;
            uint256 numerator = amountInWithFee * uint256(reserve0);
            uint256 denominator = uint256(reserve1) * 1000 + amountInWithFee;
            amountOut = numerator / denominator;
            IERC20(tokenA).safeTransfer(address(pair), amountA);
            pair.swap(amountOut, 0, address(this), "");
        }
        
        return amountOut;
    }
    
    /**
     * @notice 使用PairBC直接交换C→B
     * @param amountC 要交换的TokenC数量
     * @return 获得的TokenB数量
     * @dev 利用BC池中的价格差异获取利润
     */
    function swapCtoB(uint256 amountC) internal returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairBC);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        address token0 = pair.token0();
        uint256 amountOut;
        
        if (token0 == tokenC) {
            // C是token0，B是token1
            uint256 amountInWithFee = amountC * 997;
            uint256 numerator = amountInWithFee * uint256(reserve1);
            uint256 denominator = uint256(reserve0) * 1000 + amountInWithFee;
            amountOut = numerator / denominator;
            IERC20(tokenC).safeTransfer(address(pair), amountC);
            pair.swap(0, amountOut, address(this), "");
        } else {
            // C是token1，B是token0
            uint256 amountInWithFee = amountC * 997;
            uint256 numerator = amountInWithFee * uint256(reserve0);
            uint256 denominator = uint256(reserve1) * 1000 + amountInWithFee;
            amountOut = numerator / denominator;
            IERC20(tokenC).safeTransfer(address(pair), amountC);
            pair.swap(amountOut, 0, address(this), "");
        }
        
        return amountOut;
    }
    
    // Direct swap B → A using PairAB (convert exact amount needed)
    function swapBtoA(uint256 targetAmountA) internal returns (uint256) {
        IUniswapV2Pair pair = IUniswapV2Pair(pairAB);
        (uint112 reserve0, uint112 reserve1,) = pair.getReserves();
        
        address token0 = pair.token0();
        uint256 amountBNeeded;
        
        if (token0 == tokenA) {
            // A is token0, B is token1
            // Calculate how much B we need to get targetAmountA
            uint256 numerator = targetAmountA * uint256(reserve1) * 1000;
            uint256 denominator = (uint256(reserve0) - targetAmountA) * 997;
            amountBNeeded = (numerator / denominator) + 1;
            IERC20(tokenB).safeTransfer(address(pair), amountBNeeded);
            pair.swap(targetAmountA, 0, address(this), "");
        } else {
            // A is token1, B is token0
            uint256 numerator = targetAmountA * uint256(reserve0) * 1000;
            uint256 denominator = (uint256(reserve1) - targetAmountA) * 997;
            amountBNeeded = (numerator / denominator) + 1;
            IERC20(tokenB).safeTransfer(address(pair), amountBNeeded);
            pair.swap(0, targetAmountA, address(this), "");
        }
        
        return targetAmountA;
    }
    
    /**
     * @notice 替代路径: B→C→A 以避免PairAB的重入问题
     * @param targetAmountA 目标获得的TokenA数量
     * @return 实际获得的TokenA数量
     * @dev 通过两步交换避免直接使用借贷池进行还款
     */
    function swapBtoAViaC(uint256 targetAmountA) internal returns (uint256) {
        // 首先，通过PairBC将部分B转换为C
        // 我们需要计算从 PairAC 获得 targetAmountA 需要多少 C
        IUniswapV2Pair pairAC_contract = IUniswapV2Pair(pairAC);
        (uint112 reserveAC0, uint112 reserveAC1,) = pairAC_contract.getReserves();
        
        address token0AC = pairAC_contract.token0();
        uint256 tokenCNeeded; // 需要的TokenC数量
        
        if (token0AC == tokenA) {
            // A is token0, C is token1 in PairAC
            // Calculate how much C we need to get targetAmountA
            uint256 numerator = targetAmountA * uint256(reserveAC1) * 1000;
            uint256 denominator = (uint256(reserveAC0) - targetAmountA) * 997;
            tokenCNeeded = (numerator / denominator) + 1;
        } else {
            // A is token1, C is token0 in PairAC
            uint256 numerator = targetAmountA * uint256(reserveAC0) * 1000;
            uint256 denominator = (uint256(reserveAC1) - targetAmountA) * 997;
            tokenCNeeded = (numerator / denominator) + 1;
        }
        
        console.log("Need TokenC for conversion:", tokenCNeeded);
        
        // Now convert B to C via PairBC to get the required amount of C
        IUniswapV2Pair pairBC_contract = IUniswapV2Pair(pairBC);
        (uint112 reserveBC0, uint112 reserveBC1,) = pairBC_contract.getReserves();
        
        address token0BC = pairBC_contract.token0();
        uint256 tokenBNeeded;
        
        if (token0BC == tokenB) {
            // B is token0, C is token1 in PairBC
            uint256 numerator = tokenCNeeded * uint256(reserveBC0) * 1000;
            uint256 denominator = (uint256(reserveBC1) - tokenCNeeded) * 997;
            tokenBNeeded = (numerator / denominator) + 1;
            IERC20(tokenB).safeTransfer(address(pairBC_contract), tokenBNeeded);
            pairBC_contract.swap(0, tokenCNeeded, address(this), "");
        } else {
            // B is token1, C is token0 in PairBC
            uint256 numerator = tokenCNeeded * uint256(reserveBC1) * 1000;
            uint256 denominator = (uint256(reserveBC0) - tokenCNeeded) * 997;
            tokenBNeeded = (numerator / denominator) + 1;
            IERC20(tokenB).safeTransfer(address(pairBC_contract), tokenBNeeded);
            pairBC_contract.swap(tokenCNeeded, 0, address(this), "");
        }
        
        console.log("Converted TokenB to TokenC:", tokenBNeeded, "->", tokenCNeeded);
        
        // Finally, convert C to A via PairAC
        if (token0AC == tokenA) {
            // A is token0, C is token1
            IERC20(tokenC).safeTransfer(address(pairAC_contract), tokenCNeeded);
            pairAC_contract.swap(targetAmountA, 0, address(this), "");
        } else {
            // A is token1, C is token0
            IERC20(tokenC).safeTransfer(address(pairAC_contract), tokenCNeeded);
            pairAC_contract.swap(0, targetAmountA, address(this), "");
        }
        
        console.log("Final conversion TokenC to TokenA:", tokenCNeeded, "->", targetAmountA);
        return targetAmountA;
    }
    
    /**
     * @notice 紧急提取函数，将合约中的所有代币转移给所有者
     * @dev 只有合约所有者可以调用，用于处理意外情况
     */
    function emergencyWithdraw() external onlyOwner {
        uint256 balanceA = IERC20(tokenA).balanceOf(address(this));
        uint256 balanceB = IERC20(tokenB).balanceOf(address(this));
        uint256 balanceC = IERC20(tokenC).balanceOf(address(this));
        
        // 转移所有余额给所有者
        if (balanceA > 0) IERC20(tokenA).safeTransfer(owner(), balanceA);
        if (balanceB > 0) IERC20(tokenB).safeTransfer(owner(), balanceB);
        if (balanceC > 0) IERC20(tokenC).safeTransfer(owner(), balanceC);
    }
}