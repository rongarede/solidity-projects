# Rebase Token 项目需求与待讨论事项

## 项目概述
实现一个"按年通缩 1%"的 ERC20 Rebase 代币系统

## 核心需求
- **初始总量**: 1e8 (100,000,000) 枚
- **通缩机制**: 每过整整 1 年，总供应量减少 1%（复利通缩）
- **实现方式**: shares/index 模式全局缩放余额
- **时间标准**: 365 days = 1 年

## 技术要点
### 1. 数学计算
- 复利通缩公式: `totalSupply = initialSupply * (0.99)^years`
- 需要安全的幂运算实现（避免溢出和精度损失）
- Index 精度设计（建议 1e18）

### 2. Rebase 机制
- `lastRebaseTs` 记录上次 rebase 时间
- 支持跨多年一次性 rebase
- `index *= (99/100)^yearsElapsed`
- 防重复计算保护

### 3. 份额系统
- 内部存储: `_shares[address]`, `_totalShares`
- 实际余额: `balanceOf = _shares[addr] * index / 1e18`
- 转账时处理 shares ↔ amount 转换

### 4. ERC20 标准
- 完整实现所有标准接口
- 事件: Transfer, Approval, Rebase(yearsElapsed, newIndex)

## 待讨论和确认的技术方案

### 🔍 关键技术决策点

#### 1. 幂运算实现方案
- **方案A**: 自实现 `powFraction(base, exp)` 函数
- **方案B**: 使用 PRBMath 库
- **方案C**: 使用 ABDKMath 库
- **考虑因素**: Gas 成本、精度、依赖复杂度

#### 2. 精度和溢出处理
- Index 初始值和精度（1e18 vs 1e27）
- 大数运算的安全边界
- 最大支持年数限制

#### 3. Rebase 触发机制
- **方案A**: 仅 owner 可触发
- **方案B**: 任何人可触发（可选奖励机制）
- **方案C**: 自动触发（通过其他交易调用）

#### 4. 初始化策略
- 合约部署时的初始分配
- 是否需要 mint 功能
- Owner 权限范围

### 🧪 测试重点

#### 核心功能测试
1. **时间跨度测试**
   - 1年后单次 rebase
   - 3年后一次性 rebase
   - 不足1年调用无效果

2. **余额一致性测试**
   - Rebase 前后用户份额保持比例
   - 转账前后 shares 计算正确
   - 极端金额的精度处理

3. **边界条件测试**
   - 最大年数支持
   - 最小余额处理
   - 零余额账户

### 🏗️ 项目结构
```
src/
├── RebaseToken.sol          # 主合约
├── libraries/
│   └── MathUtils.sol       # 数学工具函数
└── interfaces/
    └── IRebaseToken.sol    # 接口定义

test/
├── RebaseToken.t.sol       # 主测试文件
└── helpers/
    └── TestHelper.sol      # 测试辅助函数

script/
└── Deploy.s.sol           # 部署脚本
```

## 技术方案确认 ✅

### 已确定方案
1. **数学库选择**: 使用 PRBMath 库实现幂运算
2. **部署目标**: Polygon 网络
3. **时间精度**: 基于区块数量判断（Polygon ~2秒/块）

### Polygon 网络特点
- **区块时间**: ~2秒/块
- **每年区块数**: `365 * 24 * 60 * 60 / 2 = 15,768,000` 块
- **Gas 成本**: 相对较低，适合频繁 rebase 操作
- **稳定性**: 区块时间相对稳定

### 具体实现方案
```solidity
uint256 constant BLOCKS_PER_YEAR = 15_768_000; // Polygon: 365天 * 24小时 * 60分 * 60秒 / 2秒
uint256 lastRebaseBlock;

function rebase() external {
    uint256 blocksElapsed = block.number - lastRebaseBlock;
    uint256 yearsElapsed = blocksElapsed / BLOCKS_PER_YEAR;
    
    if (yearsElapsed > 0) {
        // 使用 PRBMath 计算: index *= (0.99)^yearsElapsed
        index = index.mul(PRBMath.pow(99e16, yearsElapsed)) / 1e18;
        lastRebaseBlock += yearsElapsed * BLOCKS_PER_YEAR;
        emit Rebase(yearsElapsed, index);
    }
}
```

## 后续讨论要点

1. **Gas 优化策略**: 关键函数的 gas 使用评估
2. **安全考虑**: 重入攻击、整数溢出等防护
3. **升级策略**: 是否需要代理合约支持
4. **兼容性**: 与现有 DeFi 协议的兼容性考虑

## 详细实现步骤

### 第一阶段：项目初始化和基础设置
- [ ] **步骤1**: 检查项目结构，确认 foundry.toml 配置
- [ ] **步骤2**: 安装 PRBMath 依赖库
- [ ] **步骤3**: 创建基础合约文件结构
- [ ] **步骤4**: 创建接口定义文件 `IRebaseToken.sol`

### 第二阶段：核心数学库集成
- [ ] **步骤5**: 导入 PRBMath 库并测试基础功能
- [ ] **步骤6**: 实现安全的幂运算包装函数
- [ ] **步骤7**: 编写数学计算的单元测试
- [ ] **步骤8**: 验证精度和边界条件

### 第三阶段：RebaseToken 合约核心实现
- [ ] **步骤9**: 实现合约基础结构和状态变量
  - 继承 ERC20 和 Ownable
  - 定义常量（BLOCKS_PER_YEAR, INITIAL_SUPPLY 等）
  - 声明状态变量（index, lastRebaseBlock, _shares 等）
- [ ] **步骤10**: 实现构造函数和初始化逻辑
- [ ] **步骤11**: 实现 ERC20 基础视图函数
  - `name()`, `symbol()`, `decimals()`
  - `totalSupply()` - 基于 index 计算
  - `balanceOf()` - shares 转换为实际余额
- [ ] **步骤12**: 实现 shares ↔ amount 转换函数
  - `_getSharesByAmount(uint256 amount)`
  - `_getAmountByShares(uint256 shares)`

### 第四阶段：转账和授权功能
**合约文件**: `src/RebaseToken.sol` (主合约)

- [ ] **步骤13**: 实现 `transfer()` 函数
  - **位置**: RebaseToken.sol 合约中
  - **功能**: 将用户输入的 amount 转换为 shares，更新发送方和接收方的 _shares 映射
  - **逻辑**: 调用内部 `_transfer()` 函数执行实际转账
  - **事件**: 发出标准 ERC20 Transfer 事件
  
- [ ] **步骤14**: 实现 `transferFrom()` 函数  
  - **位置**: RebaseToken.sol 合约中
  - **功能**: 代理转账功能，检查并消耗 `_allowances` 映射中的授权额度
  - **逻辑**: 验证授权额度 → 执行转账 → 减少授权额度
  - **依赖**: 需要步骤16的 `_transfer()` 函数
  
- [ ] **步骤15**: 实现 `approve()` 和 `allowance()` 函数
  - **位置**: RebaseToken.sol 合约中  
  - **功能**: 
    - `approve()`: 设置 `_allowances[msg.sender][spender] = amount`
    - `allowance()`: 查询 `_allowances[owner][spender]` 的值
  - **事件**: approve() 发出 Approval 事件
  
- [ ] **步骤16**: 实现内部 `_transfer()` 辅助函数
  - **位置**: RebaseToken.sol 合约中 (internal 函数)
  - **功能**: 转账的核心逻辑实现
  - **逻辑**: 
    - 参数验证 (地址非零、余额充足)
    - 使用 `_getSharesByAmount()` 将金额转为份额
    - 更新 `_shares[from]` 和 `_shares[to]`
    - 发出 Transfer 事件
  - **依赖**: 需要步骤12的转换函数

### 第五阶段：Rebase 核心功能
- [ ] **步骤17**: 实现 `rebase()` 函数核心逻辑
  - 计算经过的区块数
  - 计算经过的年数
  - 使用 PRBMath 计算新的 index
  - 更新 lastRebaseBlock
  - 发出 Rebase 事件
- [ ] **步骤18**: 添加 rebase 前置检查
  - onlyOwner 修饰符
  - 防重复调用检查
  - 年数边界检查
- [ ] **步骤19**: 实现 `getRebaseInfo()` 视图函数
  - 返回当前 index
  - 返回距离下次 rebase 的区块数
  - 返回预期的下次 rebase 影响

### 第六阶段：事件和辅助功能
- [ ] **步骤20**: 定义所有必要的事件
  - `Rebase(uint256 yearsElapsed, uint256 newIndex)`
  - 标准 ERC20 事件
- [ ] **步骤21**: 实现管理员功能（如需要）
  - 紧急暂停功能
  - 参数调整功能
- [ ] **步骤22**: 添加完整的错误处理和自定义错误

### 第七阶段：全面测试开发
**测试文件**: `test/RebaseToken.t.sol` (主测试文件)

- [ ] **步骤23**: 创建测试基础设施
  - **位置**: `test/helpers/TestHelper.sol`
  - **功能**: 
    - 测试合约基类继承 `Test` from forge-std
    - 时间模拟函数: `skipBlocks(uint256 blocks)`, `skipYears(uint256 years)`
    - 精度比较函数: `assertApproxEqRel(uint256 a, uint256 b, uint256 maxPercentDelta)`
    - 事件验证辅助函数
  - **依赖**: forge-std/Test.sol
  
- [ ] **步骤24**: 编写基础功能测试
  - **位置**: `test/RebaseToken.t.sol`
  - **测试合约**: `RebaseTokenTest`
  - **具体测试用例**:
    ```solidity
    function testDeployment() // 合约正确部署和初始化
    function testERC20BasicInfo() // name, symbol, decimals 正确
    function testInitialSupplyAndBalance() // 初始总量和余额正确
    function testSharesAmountConversion() // _getSharesByAmount/_getAmountByShares 转换准确
    ```
  - **验证点**: 初始状态、基础 ERC20 信息、转换函数精度
  
- [ ] **步骤25**: 编写 Rebase 核心测试
  - **位置**: `test/RebaseToken.t.sol`
  - **具体测试用例**:
    ```solidity
    function testRebaseOnceAfterOneYear() {
        // 1. 记录初始总量
        // 2. vm.roll(block.number + BLOCKS_PER_YEAR)
        // 3. 执行 rebase()
        // 4. 验证 totalSupply ≈ initialSupply * 0.99
        // 5. 验证 index 更新正确
        // 6. 验证 Rebase 事件发出
    }
    
    function testMultiYearsInOneCall() {
        // 1. vm.roll(block.number + 3 * BLOCKS_PER_YEAR)
        // 2. 执行 rebase()
        // 3. 验证 totalSupply ≈ initialSupply * (0.99)^3
        // 4. 验证 yearsElapsed = 3
    }
    
    function testNoRebaseIfNotOneYear() {
        // 1. vm.roll(block.number + BLOCKS_PER_YEAR - 1)
        // 2. 执行 rebase()
        // 3. 验证 totalSupply 不变
        // 4. 验证 index 不变
    }
    
    function testRebaseOnlyOwner() {
        // 1. vm.prank(非owner地址)
        // 2. 验证 rebase() 失败
    }
    ```
  - **验证点**: 通缩计算、多年累计、时间边界、权限控制
  
- [ ] **步骤26**: 编写余额和转账测试
  - **位置**: `test/RebaseToken.t.sol` 
  - **具体测试用例**:
    ```solidity
    function testBalanceScaling() {
        // 1. 给 Alice 转账 10% 初始供应量
        // 2. 记录 Alice 初始余额比例
        // 3. 执行多次 rebase
        // 4. 验证 Alice 余额始终约等于 totalSupply * 10%
    }
    
    function testTransferBeforeAfterRebase() {
        // 1. Alice 有 1000 代币
        // 2. Alice 转给 Bob 100 代币
        // 3. 验证转账后余额正确
        // 4. 执行 rebase (总量减少 1%)
        // 5. Alice 转给 Bob 50 代币
        // 6. 验证 rebase 后转账仍然正确
    }
    
    function testLargeAmountTransfer() {
        // 测试接近总供应量的大额转账
        // 验证精度损失在可接受范围内
    }
    
    function testTransferFromWithRebase() {
        // 1. Alice approve Bob 500 代币
        // 2. 执行 rebase
        // 3. Bob 执行 transferFrom
        // 4. 验证授权余额按金额计算(不是按份额)
    }
    ```
  - **验证点**: 比例保持、转账准确性、授权机制、精度控制
  
- [ ] **步骤27**: 编写边界条件和错误测试
  - **位置**: `test/RebaseToken.t.sol`
  - **具体测试用例**:
    ```solidity
    function testZeroAmountTransfer() {
        // 验证 0 金额转账不报错但无实际效果
    }
    
    function testTransferToSelf() {
        // 验证自转账不影响余额
    }
    
    function testTransferExceedsBalance() {
        // 验证转账金额超过余额时 revert
    }
    
    function testMaxYearsLimit() {
        // 1. 跳转极大年数 (如100年)
        // 2. 验证 rebase 不会导致溢出或下溢
        // 3. 验证极小总量时的精度处理
    }
    
    function testReentrancyProtection() {
        // 部署恶意合约尝试在 transfer 中重入
        // 验证重入攻击被阻止
    }
    
    function testApprovalEdgeCases() {
        // 1. approve 0 金额
        // 2. approve 最大值 type(uint256).max
        // 3. 重复 approve 覆盖
    }
    
    function testDustAmountHandling() {
        // 测试极小金额 (1 wei) 的处理
        // 验证 shares 转换不会丢失精度
    }
    ```
  - **验证点**: 异常处理、边界值、安全防护、精度边界
  

### 第八阶段：Gas 优化和安全审计
- [ ] **步骤28**: Gas 使用分析和优化
  - 关键函数 gas 消耗测试
  - unchecked 块优化
  - 存储布局优化
- [ ] **步骤29**: 安全检查
  - 整数溢出检查
  - 重入攻击防护
  - 权限控制验证
- [ ] **步骤30**: 代码审查和重构
  - 代码风格统一
  - 注释完善
  - 函数命名优化

### 第九阶段：部署和文档
- [ ] **步骤31**: 编写部署脚本
  - 构造函数参数配置
  - 部署验证逻辑
  - 初始化检查
- [ ] **步骤32**: 创建部署文档
  - 部署步骤说明
  - 网络配置指南
  - 验证合约指南
- [ ] **步骤33**: 编写用户使用文档
  - 合约接口说明
  - Rebase 机制解释
  - 常见问题解答

### 第十阶段：最终验证和交付
- [ ] **步骤34**: 完整集成测试
  - 模拟真实使用场景
  - 长期运行测试
  - 多用户交互测试
- [ ] **步骤35**: 性能基准测试
  - Gas 使用基准
  - 响应时间测试
  - 并发处理测试
- [ ] **步骤36**: 最终代码审查和优化
- [ ] **步骤37**: 准备生产部署

## 开发进度追踪

### 已完成 ✅
- [x] 需求分析和技术方案确定
- [x] Polygon 网络适配方案设计

### 进行中 🚧
- [ ] 等待开始第一阶段实现

### 待开始 📋
- [ ] 第一阶段：项目初始化和基础设置
- [ ] 第二阶段：核心数学库集成
- [ ] 第三阶段：RebaseToken 合约核心实现
- [ ] 第四阶段：转账和授权功能
- [ ] 第五阶段：Rebase 核心功能
- [ ] 第六阶段：事件和辅助功能
- [ ] 第七阶段：全面测试开发
- [ ] 第八阶段：Gas 优化和安全审计
- [ ] 第九阶段：部署和文档
- [ ] 第十阶段：最终验证和交付

---
*创建时间: 2025-07-28*
*最后更新: 2025-07-28*
*状态: 详细实现步骤已规划，等待开始执行*