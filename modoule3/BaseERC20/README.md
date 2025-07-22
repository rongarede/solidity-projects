# BaseERC20 & TokenBank Project

本项目包含一个基于 OpenZeppelin 的 ERC20 代币合约和一个代币银行合约，实现代币的存取功能。

## 项目结构

```
BaseERC20/
├── src/
│   ├── BaseERC20.sol      # 基础 ERC20 代币合约
│   └── TokenBank.sol      # 代币银行合约
├── test/
│   ├── BaseERC20.t.sol    # BaseERC20 测试文件
│   └── TokenBank.t.sol    # TokenBank 测试文件
├── script/
│   └── Deploy.s.sol       # 部署脚本（可选）
└── foundry.toml           # Foundry 配置文件
```

## 合约说明

### BaseERC20.sol
- **功能**: 标准 ERC20 代币实现
- **代币名称**: "BaseERC20"
- **代币符号**: "BERC20"
- **总发行量**: 100,000,000 个代币 (100,000,000 * 10^18 wei)
- **特点**: 使用 OpenZeppelin 标准库，部署时将所有代币分配给部署者

### TokenBank.sol
- **功能**: 代币存取银行
- **核心功能**:
  - `deposit(uint256 amount)`: 存入指定数量的 BaseERC20 代币
  - `withdraw(uint256 amount)`: 取出指定数量的代币
  - `balanceOf(address user)`: 查询用户在银行的余额
  - `getContractBalance()`: 查询银行合约的总代币余额
- **安全特性**:
  - 重入攻击防护
  - CEI 模式 (Checks-Effects-Interactions)
  - 输入验证和错误处理

## 使用流程

### 1. 部署合约
```solidity
// 1. 部署 BaseERC20
BaseERC20 token = new BaseERC20();

// 2. 部署 TokenBank
TokenBank bank = new TokenBank(address(token));
```

### 2. 用户操作流程
```solidity
// 1. 用户需要先授权银行合约
token.approve(address(bank), amount);

// 2. 存入代币
bank.deposit(amount);

// 3. 查询余额
uint256 balance = bank.balanceOf(userAddress);

// 4. 取出代币
bank.withdraw(amount);
```

## Foundry 工具链

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## 快速开始

### 安装依赖
```shell
$ forge install OpenZeppelin/openzeppelin-contracts
```

### 编译合约
```shell
$ forge build
```

### 运行测试
```shell
# 运行所有测试
$ forge test

# 运行特定测试文件
$ forge test --match-path test/BaseERC20.t.sol
$ forge test --match-path test/TokenBank.t.sol

# 详细输出
$ forge test -vv
```

### 测试覆盖率
```shell
$ forge coverage
```

### 代码格式化
```shell
$ forge fmt
```

### Gas 使用报告
```shell
$ forge test --gas-report
```

### 启动本地节点
```shell
$ anvil
```

### 部署到本地网络
```shell
$ forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <your_private_key> --broadcast
```

## 测试用例

### BaseERC20 测试
- ✅ 代币元数据验证 (名称、符号、小数位)
- ✅ 总发行量验证
- ✅ 转账功能测试
- ✅ 授权和 transferFrom 功能测试

### TokenBank 测试
- ✅ 存款功能测试
- ✅ 取款功能测试
- ✅ 授权检查测试
- ✅ 余额不足检查测试
- ✅ 零金额操作检查测试
- ✅ 多用户操作测试

## 安全考虑

1. **重入攻击防护**: 使用自定义重入锁机制
2. **整数溢出**: Solidity 0.8+ 内置溢出检查
3. **授权检查**: 严格的 ERC20 授权机制
4. **状态一致性**: 遵循 CEI 模式，先更新状态再进行外部调用
5. **输入验证**: 对所有用户输入进行验证

## 文档

- [Foundry Book](https://book.getfoundry.sh/)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Solidity Documentation](https://docs.soliditylang.org/)

## 帮助

```shell
$ forge --help
$ anvil --help
$ cast --help
```
