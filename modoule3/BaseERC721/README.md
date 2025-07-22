# SimpleNFT - ERC721 测试合约

一个基于 OpenZeppelin 的简化版 ERC721 NFT 智能合约，用于学习和测试目的。

## 📦 项目概述

SimpleNFT 是一个遵循 ERC721 标准的 NFT 合约，提供了基础的铸造、管理和交易功能。该项目使用 Foundry 框架进行开发和测试。

## 🌟 合约特性

- ✅ **完全符合 ERC721 标准**
- ✅ **付费铸造机制**（默认 0.01 ETH）
- ✅ **管理员免费铸造**
- ✅ **供应量限制**（最大 1000 个）
- ✅ **价格动态调整**
- ✅ **元数据 URI 管理**
- ✅ **安全的资金提取**
- ✅ **所有权管理**

## 🛠️ 技术栈

- **Solidity**: ^0.8.19
- **Foundry**: 开发和测试框架
- **OpenZeppelin**: 安全的智能合约库

## 🚀 快速开始

### 安装依赖
```bash
forge install
```

### 编译合约
```bash
forge build
```

### 运行测试
```bash
forge test
```

### 详细测试输出
```bash
forge test -vvv
```

## 📋 合约功能

### 核心函数

#### 铸造功能
```solidity
// 用户付费铸造
function mint(address to) external payable

// 管理员免费铸造
function adminMint(address to, uint256 quantity) external onlyOwner
```

#### 管理功能
```solidity
// 设置铸造价格
function setMintPrice(uint256 newPrice) external onlyOwner

// 设置基础 URI
function setBaseURI(string memory baseTokenURI) external onlyOwner

// 提取合约余额
function withdraw() external onlyOwner
```

#### 查询功能
```solidity
// 获取总供应量
function totalSupply() public view returns (uint256)

// 获取合约余额
function getBalance() external view returns (uint256)

// 检查是否售罄
function isSoldOut() external view returns (bool)
```

## 🧪 测试覆盖

项目包含全面的测试用例：

- ✅ **基础铸造测试**
- ✅ **管理员铸造测试**
- ✅ **价格设置测试**
- ✅ **支付不足失败测试**
- ✅ **供应量超限失败测试**
- ✅ **资金提取测试**

运行特定测试：
```bash
# 运行单个测试
forge test --match-test testMint

# 运行失败测试
forge test --match-test test_Revert
```

## 📊 Gas 优化

查看 Gas 使用情况：
```bash
forge test --gas-report
```

生成 Gas 快照：
```bash
forge snapshot
```

## 🚀 部署指南

### 本地部署（Anvil）

1. 启动本地节点：
```bash
anvil
```

2. 部署合约：
```bash
forge script script/DeploySimpleNFT.s.sol --rpc-url http://localhost:8545 --private-key <PRIVATE_KEY> --broadcast
```

### 测试网部署

#### Sepolia 测试网
```bash
forge script script/DeploySimpleNFT.s.sol \
  --rpc-url https://sepolia.infura.io/v3/YOUR_PROJECT_ID \
  --private-key YOUR_PRIVATE_KEY \
  --broadcast \
  --verify
```

## 🎯 使用示例

### 与合约交互

```bash
# 获取合约信息
cast call CONTRACT_ADDRESS "name()" --rpc-url RPC_URL

# 查看总供应量
cast call CONTRACT_ADDRESS "totalSupply()" --rpc-url RPC_URL

# 铸造 NFT
cast send CONTRACT_ADDRESS "mint(address)" YOUR_ADDRESS \
  --value 0.01ether \
  --private-key YOUR_PRIVATE_KEY \
  --rpc-url RPC_URL
```

### JavaScript 交互示例

```javascript
// 使用 ethers.js
const contract = new ethers.Contract(contractAddress, abi, signer);

// 铸造 NFT
await contract.mint(userAddress, { value: ethers.utils.parseEther("0.01") });

// 查询余额
const balance = await contract.balanceOf(userAddress);

// 获取代币 URI
const tokenURI = await contract.tokenURI(tokenId);
```

## 📁 项目结构

```
BaseERC721/
├── src/
│   └── SimpleNFT.sol          # 主合约文件
├── test/
│   └── SimpleNFT.t.sol        # 测试文件
├── script/
│   └── DeploySimpleNFT.s.sol  # 部署脚本
├── lib/                       # 依赖库
├── foundry.toml              # Foundry 配置
└── README.md                 # 项目文档
```

## 🔐 安全注意事项

- ✅ 使用 OpenZeppelin 的安全合约
- ✅ 实现了访问控制
- ✅ 防止重入攻击
- ✅ 输入验证和错误处理
- ⚠️ 仅用于测试，生产环境需要更多安全审计

## 📝 常见问题

### Q: 如何修改最大供应量？
A: 修改合约中的 `MAX_SUPPLY` 常量并重新部署。

### Q: 如何设置不同的元数据 URI？
A: 调用 `setBaseURI()` 函数更新基础 URI。

### Q: 如何查看测试覆盖率？
A: 使用 `forge coverage` 命令查看代码覆盖率。

## 📄 许可证

MIT License - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🔗 相关链接

- [OpenZeppelin 合约](https://docs.openzeppelin.com/contracts/)
- [ERC721 标准](https://eips.ethereum.org/EIPS/eip-721)
-