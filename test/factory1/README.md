# Meme Token 发行平台

这是一个基于 EIP-1167 Minimal Proxy 模式的 Meme Token 发行平台，使用 Foundry 框架开发。

## 项目概述

### 核心特性

- **工厂合约模式**: 使用 `MemeFactory.sol` 作为主要工厂合约
- **Minimal Proxy**: 采用 EIP-1167 标准降低部署成本
- **ERC20 代币**: 每个 Meme 都是标准的 ERC20 代币
- **费用分配**: 1% 平台费用，99% 给代币创建者
- **分批铸造**: 支持按固定数量分批铸造代币

### 合约架构

#### MemeToken.sol
- ERC20 代币模板合约
- 支持初始化函数用于 Minimal Proxy
- 只允许工厂合约铸造代币
- 固定名称 "MemeToken"，符号可自定义

#### MemeFactory.sol  
- 工厂合约，管理所有 Meme 代币
- 部署新的 Meme 代币（使用 Minimal Proxy）
- 处理代币铸造和费用分配
- 跟踪所有已部署的代币

## 使用方法

### 部署新的 Meme 代币

```solidity
function deployMeme(
    string memory symbol,     // 代币符号，如 "PEPE"
    uint256 totalSupply,      // 总供应量
    uint256 perMint,          // 每次铸造数量
    uint256 price             // 每个代币价格（wei）
) external returns (address memeToken)
```

### 铸造代币

```solidity
function mintMeme(address tokenAddr) external payable
```

- 支付 `perMint * price` 的费用
- 自动分配费用：1% 给平台，99% 给创建者
- 铸造 `perMint` 数量的代币给调用者

## 测试

项目包含完整的测试套件，覆盖所有主要功能：

```bash
forge test
```

### 测试用例

- ✅ 部署 Meme 代币
- ✅ 铸造代币和费用分配
- ✅ 多次铸造
- ✅ 多余支付的退款
- ✅ 错误处理（参数无效、供应不足、支付不足等）
- ✅ 访问控制
- ✅ 多个 Meme 代币管理

## 部署说明

1. 首先部署 `MemeToken` 模板合约
2. 部署 `MemeFactory` 合约，传入模板地址和平台所有者地址
3. 用户可以通过工厂合约创建和铸造 Meme 代币

## 安全特性

- **重入攻击保护**: 使用 OpenZeppelin 的 `ReentrancyGuard`
- **访问控制**: 只有工厂合约可以铸造代币
- **参数验证**: 严格的输入参数检查
- **溢出保护**: 使用 Solidity 0.8+ 的内置溢出检查
- **初始化保护**: 防止模板合约被重复初始化

## Gas 优化

- 使用 EIP-1167 Minimal Proxy 大幅降低部署成本
- 高效的存储布局
- 批量操作减少交易次数

## 许可证

MIT License
