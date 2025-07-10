# BigBank 前端 MVP 实现方案

## 页面结构说明

### 基本布局
- **标题区域**: 显示 "BigBank DApp" 标题
- **钱包信息区域**: 显示当前连接的钱包地址（截断显示）
- **余额显示区域**: 
  - ERC20 Token 余额（从 ERC20 合约读取）
  - Bank 合约中的存款余额（从 Bank 合约读取）
- **存款操作区域**: 
  - 数字输入框（存款金额）
  - "存款" 按钮（触发 approve + deposit）
- **取款操作区域**: 
  - "取款" 按钮（触发 withdraw）

### 页面交互
- 页面加载时自动获取钱包地址和余额信息
- 所有操作结果通过 `alert()` 反馈
- 操作完成后手动刷新页面查看更新后的余额

## 合约交互流程

### 初始化流程
1. 使用 `createWalletClient` 创建钱包客户端
2. 使用 `getAccount` 获取当前钱包地址
3. 使用 `readContract` 读取 ERC20 Token 余额
4. 使用 `readContract` 读取 Bank 合约中的用户存款余额

### 存款流程
1. 用户输入存款金额
2. 使用 `parseUnits` 将输入金额转换为 wei 单位
3. 第一步：调用 `writeContract` 执行 ERC20 的 `approve()` 函数
4. 使用 `waitForTransactionReceipt` 等待 approve 交易确认
5. 第二步：调用 `writeContract` 执行 Bank 的 `deposit()` 函数
6. 使用 `waitForTransactionReceipt` 等待 deposit 交易确认
7. 使用 `alert()` 显示操作结果

### 取款流程
1. 调用 `writeContract` 执行 Bank 的 `withdraw()` 函数
2. 使用 `waitForTransactionReceipt` 等待交易确认
3. 使用 `alert()` 显示操作结果

## 所用 viem 模块说明

### 核心模块
- **createWalletClient**: 创建与 MetaMask 等钱包的连接客户端
- **getAccount**: 获取当前连接的钱包账户信息
- **readContract**: 读取合约状态（余额查询）
- **writeContract**: 执行合约写入操作（approve、deposit、withdraw）
- **waitForTransactionReceipt**: 等待交易确认，获取交易结果
- **formatUnits**: 将 wei 单位转换为可读的 ether 单位显示
- **parseUnits**: 将用户输入的 ether 单位转换为 wei 单位

### 硬编码参数
- **合约地址**: ERC20 Token 合约地址、Bank 合约地址
- **ABI**: ERC20 标准 ABI（approve、balanceOf）、Bank 合约 ABI（deposit、withdraw、balances）
- **链信息**: 网络配置（如 Sepolia 测试网）

## 技术实现要点

### 错误处理
- 所有异步操作使用 try-catch 包装
- 失败情况通过 `alert()` 显示错误信息
- 不进行复杂的错误分类或重试机制

### 状态管理
- 不使用状态管理库
- 页面数据通过函数调用实时获取
- 操作完成后提示用户手动刷新页面

### 用户体验
- 操作过程中按钮保持可点击状态
- 不显示加载状态或进度指示
- 依赖 MetaMask 的原生交易确认界面

这个方案可以在 2-3 小时内完成开发，是一个真正的最小可行产品，适合快速验证 BigBank 合约的基本功能。