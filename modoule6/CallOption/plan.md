# 看涨期权代币测试项目开发计划

## 项目概述
实现一个最小化的看涨期权代币系统，用于测试和学习目的。使用Solidity 0.8.24、Foundry框架和OpenZeppelin Contracts 5.0.1，实现基础的期权代币铸造、行权、过期回收功能，以及模拟期权购买的简单交易对功能。


## 2. 核心合约实现（2小时）

### 2.1 OptionSeries.sol基础框架
- [ ] 设置合约继承
  - 继承ERC20
  - 继承Ownable
- [ ] 定义核心状态变量
  - strikePrice：行权价格（2000 ether）
  - expiry：过期时间（部署时间+7天）
  - totalCollateral：总抵押ETH数量
  - pairCreated：交易对是否已创建
  - optionReserve：期权代币储备
  - usdtReserve：USDT储备
  - usdtToken：USDT合约地址
- [ ] 实现构造函数
  - 设置代币名称为"Call Option"，符号为"CALL"
  - 初始化strikePrice和expiry
  - 设置owner

### 2.2 实现mint()函数
- [ ] 函数签名：`function mint() external payable`
- [ ] 基础验证：检查msg.value > 0
- [ ] 核心逻辑：
  - 接收ETH作为抵押
  - 铸造等量的期权代币给调用者
  - 更新totalCollateral

### 2.3 实现exercise()函数
- [ ] 函数签名：`function exercise(uint256 amount) external payable`
- [ ] 基础验证：
  - 检查未过期：`block.timestamp <= expiry`
  - 检查用户有足够的期权代币
  - 检查用户支付了行权费用
- [ ] 核心逻辑：
  - 销毁用户的期权代币
  - 转账ETH给用户（模拟获得标的资产）
  - 更新totalCollateral

### 2.4 实现collectExpired()函数
- [ ] 函数签名：`function collectExpired() external onlyOwner`
- [ ] 基础验证：检查已过期：`block.timestamp > expiry`
- [ ] 核心逻辑：
  - 计算剩余的抵押ETH
  - 转账给owner
  - 清空totalCollateral

### 2.5 实现createPair()函数（模拟期权购买）
- [ ] 函数签名：`function createPair(address usdtAddress, uint256 optionAmount, uint256 usdtAmount) external`
- [ ] 添加状态变量：
  - pairCreated：是否已创建交易对
  - optionPrice：期权价格（如行权价的5%）
- [ ] 基础验证：
  - 检查未创建过交易对
  - 检查用户有足够的期权代币
  - 检查金额大于0
- [ ] 核心逻辑：
  - 从用户转入期权代币和USDT
  - 创建简单的流动性池（存储两种代币）
  - 标记pairCreated = true
  - 设置期权价格（例如：100 USDT per option）

### 2.6 实现buyOption()函数
- [ ] 函数签名：`function buyOption(uint256 usdtAmount) external`
- [ ] 基础验证：
  - 检查交易对已创建
  - 检查流动性池有足够的期权代币
- [ ] 价格计算：
  - 使用固定价格模型（如100 USDT = 1个期权）
  - 或使用简单的恒定乘积公式
- [ ] 核心逻辑：
  - 从用户转入USDT
  - 计算可获得的期权代币数量
  - 转移期权代币给用户
  - 更新储备量

## 3. 基础测试实现（1.5小时）

### 3.1 测试环境设置
- [ ] 创建OptionSeries.t.sol
- [ ] 导入必要的测试库
- [ ] 设置测试合约和辅助变量
- [ ] 编写setUp()函数部署合约

### 3.2 核心功能测试
- [ ] test_mint_success()
  - 用户发送1 ETH
  - 验证获得1 ether的期权代币
  - 验证totalCollateral更新
- [ ] test_exercise_success()
  - 先铸造期权代币
  - 支付行权费用进行行权
  - 验证代币被销毁，ETH被转账
- [ ] test_collectExpired_success()
  - 等待过期（使用vm.warp）
  - owner调用collectExpired
  - 验证ETH被成功回收

### 3.3 基本异常测试
- [ ] test_mint_zero_eth()
  - 尝试不发送ETH进行铸造
  - 验证交易失败
- [ ] test_exercise_after_expiry()
  - 时间推进到过期后
  - 尝试行权
  - 验证交易失败
- [ ] test_collectExpired_before_expiry()
  - 在未过期时尝试回收
  - 验证交易失败
- [ ] test_collectExpired_not_owner()
  - 非owner尝试回收
  - 验证交易失败

### 3.4 期权购买功能测试
- [ ] test_createPair_success()
  - owner铸造期权代币
  - owner创建期权-USDT交易对
  - 验证交易对创建成功
- [ ] test_buyOption_success()
  - 创建交易对后
  - 用户使用USDT购买期权
  - 验证期权代币转移和USDT支付
- [ ] test_createPair_twice()
  - 尝试创建两次交易对
  - 验证第二次失败

## 4. 部署脚本（30分钟）

### 4.1 Deploy.s.sol实现
- [ ] 创建部署脚本继承Script
- [ ] 实现run()函数
- [ ] 部署OptionSeries合约
- [ ] 输出部署地址和基本信息

## 5. 项目完成和验证（30分钟）

### 5.1 功能验证
- [ ] 运行所有测试：`forge test -vvv`
- [ ] 确保所有测试通过
- [ ] 检查基本功能完整性

### 5.2 简单文档
- [ ] 创建README.md
- [ ] 说明项目用途（测试/学习）
- [ ] 列出主要功能
- [ ] 提供基本使用说明

## 交付成果

本测试项目将提供以下文件：

1. **src/OptionSeries.sol** - 基础看涨期权代币合约
   - mint()：铸造期权代币
   - exercise()：行权功能
   - collectExpired()：过期回收
   - createPair()：创建期权-USDT交易对
   - buyOption()：使用USDT购买期权

2. **test/OptionSeries.t.sol** - 基础测试套件
   - 3个正常功能测试
   - 4个异常情况测试
   - 3个期权购买相关测试

3. **script/Deploy.s.sol** - 简单部署脚本

4. **README.md** - 项目说明文档

## 时间估算
- 总时长：约4-5小时
- 适合作为学习项目或概念验证
- 专注于核心功能理解，不追求生产级品质