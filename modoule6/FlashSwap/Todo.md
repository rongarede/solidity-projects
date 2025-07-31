# FlashSwap 套利项目开发流程

## 开发阶段细分

### 第一阶段：项目初始化 ✅
1. **环境配置** ✅
   - 需要在 .env 文件中配置：
     ```
     POLYGON_RPC_URL=https://polygon-rpc.com
     PRIVATE_KEY=your_private_key_here
     POLYGONSCAN_API_KEY=your_api_key_here
     ```

### 第二阶段：基础合约开发
3. **创建 ERC20 代币合约**
   - 开发 `src/tokens/TokenA.sol`
   - 开发 `src/tokens/TokenB.sol`
   - 每个代币设置 1,000,000 初始供应量
   - **简化设计**：只需两个代币即可实现套利

4. **编译和基础测试**
   ```bash
   forge build
   forge test --match-contract TokenTest
   ```

### 第三阶段：FlashSwap 合约开发
5. **FlashSwap 合约基础架构**
   - 创建 `src/FlashSwapArbitrage.sol` 合约文件
   - 继承 `IUniswapV2Callee` 接口
   - 定义必要的状态变量：代币地址、交易对地址、路由地址

6. **核心功能实现**
   
   **6.1 合约初始化**
   - 构造函数设置代币地址和交易对地址
   - 保存 QuickSwap 路由合约地址
   
   **6.2 套利执行函数**
   - 创建 `executeArbitrage` 函数作为套利入口
   - 计算要借取的代币数量
   - 调用交易对的 `swap` 函数发起 flashswap
   
   **6.3 回调函数实现**
   - 实现 `uniswapV2Call` 回调函数
   - 验证调用者是合法的 pair 合约
   - 执行套利交换逻辑：
     * 将借到的 TokenA 通过路由换成 TokenB
     * 将 TokenB 通过路由换成 TokenC  
     * 将部分 TokenC 换回 TokenA 用于偿还
   - 偿还 flashswap（本金 + 0.3% 手续费）

7. **代币交换实现**
   - 在回调函数中实现具体的代币兑换操作
   - 调用 QuickSwap Router 合约进行 A→B、B→C、C→A 的代币交换
   - 计算每次交换所需的最小输出数量

8. **合约测试**
   ```bash
   forge test --match-contract FlashSwapTest
   ```

### 第四阶段：部署脚本开发（简化版）
7. **一站式部署脚本**
   - 开发 `script/Deploy.s.sol`
   - 部署三个 ERC20 代币（TokenA, TokenB, TokenC）
   - 创建三个交易对：
     * **PairAB**: TokenA ↔ TokenB
     * **PairBC**: TokenB ↔ TokenC  
     * **PairAC**: TokenA ↔ TokenC
   - **精心设计的流动性比例**：
     * **PairAB**: 1000 TokenA : 1500 TokenB (1 A ≈ 1.5 B)
     * **PairBC**: 1000 TokenB : 400 TokenC (1 B ≈ 0.4 C)
     * **PairAC**: 1000 TokenA : 1000 TokenC (1 A ≈ 1 C)
   - **套利机会**：A→C→B 路径得到 ~0.6B，而 PairAB 中 1A=1.5B，存在巨大套利空间
   - 部署 FlashSwap 套利合约
   - 输出所有关键合约地址

8. **套利测试脚本**
   - 开发 `script/Test.s.sol`
   - 执行套利操作测试
   - 验证套利结果和利润
   - 包含调试和故障排除功能

### 第五阶段：测试和验证
9. **单元测试开发**
    - 开发 `test/tokens/TokenTest.t.sol`
    - 开发 `test/FlashSwapTest.t.sol`
    - 测试所有核心功能

10. **集成测试开发**
    - 开发 `test/integration/ArbitrageIntegration.t.sol`
    - 测试完整套利流程
    - 验证盈利计算

11. **Fork 测试**
    ```bash
    forge test --fork-url https://polygon-rpc.com
    ```

### 第六阶段：部署执行（简化版）
12. **一键部署所有合约**
    ```bash
    # 一次性完成所有部署，包含优化的流动性比例
    forge script script/Deploy.s.sol --broadcast --fork-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY
    ```
    
    **预期流动性配置**：
    - PairAB: 1000 A : 1500 B → 1 A = 1.5 B
    - PairBC: 1000 B : 400 C → 1 B = 0.4 C  
    - PairAC: 1000 A : 1000 C → 1 A = 1 C
    
    **套利逻辑验证**：
    - 直接路径：1 A → 1.5 B (通过 PairAB)
    - 间接路径：1 A → 1 C → 2.5 B (通过 PairAC → PairBC)
    - **套利空间**：间接路径比直接路径多获得 1 B，扣除手续费后仍有显著利润

13. **执行套利测试**
    ```bash
    # 执行套利测试，验证实际盈利
    forge script script/Test.s.sol --broadcast --fork-url $POLYGON_RPC_URL --private-key $PRIVATE_KEY
    ```

### 第七阶段：问题诊断和优化
14. **新流动性配置验证**
    - 验证三个交易对的实际储备比例
    - 确认套利路径：A→C→B→A 的数学正确性  
    - **理论计算验证**：
      * 1 A → 1 C (PairAC, 1:1 比例)
      * 1 C → 2.5 B (PairBC, 1:2.5 比例，因为 1000B:400C)
      * 需偿还：1.003 A (0.3% 手续费)
      * 预期利润：约 1.5 B (2.5B - 转换回 A 的成本)

15. **套利执行优化**
    - 修正之前的余额不足错误
    - 基于新的价格比例重新计算交换数量
    - 确保回调函数中的偿还逻辑正确
    - 验证最终能够盈利并提取利润

16. **性能和安全优化**
    - Gas 使用优化
    - 错误处理完善
    - 添加必要的安全检查

### 第八阶段：文档和清理
17. **代码注释完善**
    - 为所有合约添加详细注释
    - 编写函数说明文档
    - 添加使用示例和注意事项

18. **最终测试和验证**
    - 运行完整测试套件
    - 验证修复后的套利功能
    - 确认所有问题已解决