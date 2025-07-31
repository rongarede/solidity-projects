# SimpleLeverageDEX 测试计划

## 测试概述
针对 SimpleLeverageDEX 合约的完整测试方案，覆盖所有 TODO 完成后的功能点，确保 vAMM 杠杆交易逻辑正确性和安全性。

---

## 测试环境设置

### 初始配置
- **虚拟池初始状态**: vETHAmount = 1000, vUSDCAmount = 2000000 (价格 = 2000 USDC/ETH)
- **vK 常数**: 2,000,000,000
- **模拟 USDC**: 部署 ERC20 测试代币
- **测试账户**: Alice, Bob, Charlie (各有 10000 USDC)

---

## Phase 1: 基础功能测试

### Test 1.1: 合约初始化测试
**目的**: 验证合约正确初始化
```solidity
function testInitialization() public {
    assertEq(dex.vETHAmount(), 1000);
    assertEq(dex.vUSDCAmount(), 2000000);
    assertEq(dex.vK(), 2000000000);
}
```
**预期结果**: 所有初始值正确设置

### Test 1.2: 开多头头寸测试
**目的**: 测试做多逻辑
```solidity
function testOpenLongPosition() public {
    vm.prank(alice);
    dex.openPosition(1000, 2, true); // 1000 USDC, 2倍杠杆, 做多
    
    (uint256 margin, uint256 borrowed, int256 position) = dex.positions(alice);
    assertEq(margin, 1000);
    assertEq(borrowed, 1000);
    assertTrue(position > 0); // 多头持仓为正
}
```
**预期结果**: 
- 保证金: 1000 USDC
- 借款: 1000 USDC  
- 持仓: 约 1 virtual ETH
- vUSDCAmount 增加, vETHAmount 减少

### Test 1.3: 开空头头寸测试
**目的**: 测试做空逻辑
```solidity
function testOpenShortPosition() public {
    vm.prank(bob);
    dex.openPosition(1000, 3, false); // 1000 USDC, 3倍杠杆, 做空
    
    (uint256 margin, uint256 borrowed, int256 position) = dex.positions(bob);
    assertEq(margin, 1000);
    assertEq(borrowed, 2000);
    assertTrue(position < 0); // 空头持仓为负
}
```
**预期结果**:
- 保证金: 1000 USDC
- 借款: 2000 USDC
- 持仓: 约 -1.5 virtual ETH
- vUSDCAmount 减少, vETHAmount 增加

### Test 1.4: PnL 计算测试
**目的**: 验证盈亏计算准确性
```solidity
function testPnLCalculation() public {
    // Alice 开多头
    vm.prank(alice);
    dex.openPosition(1000, 2, true);
    
    // Bob 开空头，推高价格，Alice 应该盈利
    vm.prank(bob);
    dex.openPosition(1000, 2, false);
    
    int256 alicePnL = dex.calculatePnL(alice);
    assertTrue(alicePnL > 0); // Alice 做多盈利
    
    int256 bobPnL = dex.calculatePnL(bob);
    assertTrue(bobPnL < 0); // Bob 做空亏损
}
```

---

## Phase 2: 头寸管理测试

### Test 2.1: 成功平仓测试
**目的**: 测试正常平仓流程
```solidity
function testClosePositionSuccess() public {
    uint256 initialBalance = usdc.balanceOf(alice);
    
    vm.prank(alice);
    dex.openPosition(1000, 2, true);
    
    // 创建价格变动
    vm.prank(bob);
    dex.openPosition(500, 2, false);
    
    vm.prank(alice);
    dex.closePosition();
    
    // 验证头寸已关闭
    (uint256 margin, uint256 borrowed, int256 position) = dex.positions(alice);
    assertEq(margin, 0);
    assertEq(borrowed, 0);
    assertEq(position, 0);
    
    // 验证资金变化
    uint256 finalBalance = usdc.balanceOf(alice);
    // finalBalance 应反映 PnL
}
```

### Test 2.2: 盈利平仓测试
**目的**: 验证盈利情况下的平仓
```solidity
function testClosePositionWithProfit() public {
    uint256 initialBalance = usdc.balanceOf(alice);
    
    // Alice 开多头
    vm.prank(alice);
    dex.openPosition(1000, 2, true);
    
    // 推高价格
    vm.prank(bob);
    dex.openPosition(2000, 3, false);
    
    int256 pnl = dex.calculatePnL(alice);
    assertTrue(pnl > 0); // 确认有盈利
    
    vm.prank(alice);
    dex.closePosition();
    
    uint256 finalBalance = usdc.balanceOf(alice);
    assertTrue(finalBalance > initialBalance); // 余额应增加
}
```

### Test 2.3: 亏损平仓测试
**目的**: 验证亏损情况下的平仓
```solidity
function testClosePositionWithLoss() public {
    uint256 initialBalance = usdc.balanceOf(alice);
    
    // Alice 开多头
    vm.prank(alice);
    dex.openPosition(1000, 2, true);
    
    // 压低价格
    vm.prank(bob);
    dex.openPosition(3000, 2, true);
    
    int256 pnl = dex.calculatePnL(alice);
    assertTrue(pnl < 0); // 确认有亏损
    
    vm.prank(alice);
    dex.closePosition();
    
    uint256 finalBalance = usdc.balanceOf(alice);
    assertTrue(finalBalance < initialBalance); // 余额应减少
}
```

---

## Phase 3: 清算机制测试

### Test 3.1: 清算条件检查测试
**目的**: 验证清算阈值计算
```solidity
function testLiquidationThreshold() public {
    // Alice 开高杠杆多头
    vm.prank(alice);
    dex.openPosition(1000, 10, true); // 10倍杠杆
    
    // 大幅压低价格
    vm.prank(bob);
    dex.openPosition(5000, 5, true);
    
    int256 pnl = dex.calculatePnL(alice);
    
    // 检查是否达到清算条件 (亏损 > 保证金的80%)
    bool shouldLiquidate = pnl < -800; // -800 = -1000 * 0.8
    
    if (shouldLiquidate) {
        // 应该可以被清算
        vm.prank(charlie);
        dex.liquidatePosition(alice);
        
        // 验证头寸已清算
        (uint256 margin, uint256 borrowed, int256 position) = dex.positions(alice);
        assertEq(position, 0);
    }
}
```

### Test 3.2: 清算执行测试
**目的**: 测试清算执行逻辑
```solidity
function testLiquidationExecution() public {
    uint256 charlieInitialBalance = usdc.balanceOf(charlie);
    
    // Alice 开高杠杆头寸
    vm.prank(alice);
    dex.openPosition(1000, 10, true);
    
    // 创造清算条件
    vm.prank(bob);
    dex.openPosition(8000, 3, true);
    
    // Charlie 执行清算
    vm.prank(charlie);
    dex.liquidatePosition(alice);
    
    // 验证 Alice 头寸已清除
    (uint256 margin, uint256 borrowed, int256 position) = dex.positions(alice);
    assertEq(position, 0);
    
    // 验证 Charlie 获得清算奖励
    uint256 charlieFinalBalance = usdc.balanceOf(charlie);
    assertTrue(charlieFinalBalance > charlieInitialBalance);
}
```

### Test 3.3: 防止自我清算测试
**目的**: 确保用户不能清算自己
```solidity
function testCannotSelfLiquidate() public {
    // Alice 开头寸
    vm.prank(alice);
    dex.openPosition(1000, 10, true);
    
    // 创造清算条件
    vm.prank(bob);
    dex.openPosition(8000, 3, true);
    
    // Alice 尝试清算自己应该失败
    vm.prank(alice);
    vm.expectRevert("Cannot liquidate own position");
    dex.liquidatePosition(alice);
}
```

---

## Phase 4: 边界条件和错误处理测试

### Test 4.1: 重复开仓测试
**目的**: 防止用户开多个头寸
```solidity
function testCannotOpenMultiplePositions() public {
    vm.prank(alice);
    dex.openPosition(1000, 2, true);
    
    vm.prank(alice);
    vm.expectRevert("Position already open");
    dex.openPosition(500, 2, false);
}
```

### Test 4.2: 无头寸平仓测试
**目的**: 防止无头寸时平仓
```solidity
function testCannotCloseNonexistentPosition() public {
    vm.prank(alice);
    vm.expectRevert("No open position");
    dex.closePosition();
}
```

### Test 4.3: 保证金不足测试
**目的**: 测试保证金不足时的处理
```solidity
function testInsufficientMargin() public {
    // Alice 只有少量 USDC
    vm.prank(alice);
    vm.expectRevert("ERC20: transfer amount exceeds balance");
    dex.openPosition(20000, 2, true); // 超过余额的保证金
}
```

### Test 4.4: 极端价格变动测试
**目的**: 测试极端市场条件
```solidity
function testExtremePriceMovement() public {
    // 开小头寸
    vm.prank(alice);
    dex.openPosition(100, 2, true);
    
    // 极端价格操作
    vm.prank(bob);
    dex.openPosition(10000, 10, true);
    
    // 验证系统仍然稳定
    int256 pnl = dex.calculatePnL(alice);
    // PnL 应该在合理范围内
}
```

---

## Phase 5: vAMM 机制测试

### Test 5.1: 恒定乘积验证
**目的**: 确保 x*y=k 公式正确执行
```solidity
function testConstantProduct() public {
    uint256 initialK = dex.vK();
    
    vm.prank(alice);
    dex.openPosition(1000, 2, true);
    
    uint256 newK = dex.vETHAmount() * dex.vUSDCAmount();
    assertEq(newK, initialK); // K 应该保持不变
}
```

### Test 5.2: 价格影响测试
**目的**: 验证大额交易的价格影响
```solidity
function testPriceImpact() public {
    uint256 initialPrice = dex.vUSDCAmount() / dex.vETHAmount(); // 2000
    
    // 大额做多操作
    vm.prank(alice);
    dex.openPosition(5000, 5, true);
    
    uint256 newPrice = dex.vUSDCAmount() / dex.vETHAmount();
    assertTrue(newPrice > initialPrice); // 价格应该上涨
}
```

### Test 5.3: 滑点计算测试
**目的**: 验证滑点计算正确性
```solidity
function testSlippage() public {
    uint256 initialPrice = dex.vUSDCAmount() / dex.vETHAmount();
    
    vm.prank(alice);
    dex.openPosition(1000, 2, true);
    
    uint256 finalPrice = dex.vUSDCAmount() / dex.vETHAmount();
    
    // 计算实际滑点
    uint256 slippage = ((finalPrice - initialPrice) * 100) / initialPrice;
    
    // 滑点应在合理范围内 (例如 < 5%)
    assertTrue(slippage < 5);
}
```

---

## Phase 6: 集成测试

### Test 6.1: 多用户交易场景
**目的**: 模拟真实交易环境
```solidity
function testMultiUserTrading() public {
    // Alice 开多头
    vm.prank(alice);
    dex.openPosition(1000, 3, true);
    
    // Bob 开空头
    vm.prank(bob);
    dex.openPosition(1500, 2, false);
    
    // Charlie 开多头
    vm.prank(charlie);
    dex.openPosition(800, 4, true);
    
    // 验证所有头寸都正确记录
    (, , int256 alicePos) = dex.positions(alice);
    (, , int256 bobPos) = dex.positions(bob);
    (, , int256 charliePos) = dex.positions(charlie);
    
    assertTrue(alicePos > 0);   // Alice 多头
    assertTrue(bobPos < 0);     // Bob 空头  
    assertTrue(charliePos > 0); // Charlie 多头
}
```

### Test 6.2: 连续交易测试
**目的**: 测试连续开仓平仓
```solidity
function testSequentialTrading() public {
    // Round 1
    vm.prank(alice);
    dex.openPosition(1000, 2, true);
    vm.prank(alice);
    dex.closePosition();
    
    // Round 2
    vm.prank(alice);
    dex.openPosition(1500, 3, false);
    vm.prank(alice);
    dex.closePosition();
    
    // 验证最终状态正确
    (, , int256 position) = dex.positions(alice);
    assertEq(position, 0);
}
```

---

## 测试执行命令

```bash
# 运行所有测试
forge test

# 运行特定测试文件
forge test --match-contract SimpleLeverageDEXTest

# 运行特定测试函数
forge test --match-test testOpenLongPosition

# 显示详细输出和 gas 使用
forge test -vvv --gas-report

# 生成覆盖率报告
forge coverage
```

---

## 预期测试结果

### 成功标准
- **功能测试**: 所有基础功能正常工作
- **PnL 计算**: 多空方向和金额计算正确
- **清算机制**: 在正确条件下触发清算
- **vAMM 机制**: 价格变动符合 x*y=k 公式
- **边界处理**: 错误条件正确处理
- **安全性**: 无重入、溢出等安全问题

### 覆盖率目标
- **行覆盖率**: >95%
- **分支覆盖率**: >90%
- **函数覆盖率**: 100%

### 是否通过判定
只有当所有测试用例都通过，且覆盖率达到目标时，才认为 TODO 部分实现正确，可以进入生产环境。