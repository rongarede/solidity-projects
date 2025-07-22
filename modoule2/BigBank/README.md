# BigBank System

一个基于 Solidity 的去中心化银行系统，包含用户存取款功能和管理员权限控制。

## 项目结构

```
BigBank/
├── src/
│   ├── BigBank.sol        # 主银行合约
│   ├── Admin.sol          # 管理员合约
│   └── IBank.sol          # 银行接口定义
├── test/
│   └── BigBankSystem.t.sol # 系统集成测试
└── foundry.toml           # Foundry 配置文件
```

## 合约说明

### BigBank.sol
- **功能**: 核心银行合约，处理用户存取款
- **主要特性**:
  - 最小存款要求: 0.001 ETH
  - 用户余额管理
  - 所有权转移支持
  - 存款和取款事件记录

### Admin.sol  
- **功能**: 管理员合约，控制银行资金
- **权限控制**:
  - 只有合约所有者可以提取银行资金
  - 提供资金查询功能
  - 管理员操作事件记录

### IBank.sol
- **功能**: 银行接口定义
- **标准化**: 定义银行合约必须实现的接口

## 核心功能

### 用户操作
```solidity
// 存款 (最少 0.001 ETH)
bigBank.deposit{value: amount}();

// 取款
bigBank.withdraw(amount);

// 查询余额
uint256 balance = bigBank.balances(userAddress);
```

### 管理员操作
```solidity
// 管理员提取银行所有资金
admin.adminWithdraw(IBank(bankAddress));

// 查询管理员合约余额
uint256 balance = admin.getBalance();
```

## 安全机制

1. **最小存款限制**: 防止小额垃圾交易
2. **权限控制**: 只有授权管理员可以提取资金
3. **余额检查**: 严格的余额验证机制
4. **事件记录**: 完整的操作日志追踪

## 测试用例

### 已实现测试
- ✅ 最小存款要求验证
- ✅ 管理员资金提取功能
- ✅ 权限控制验证
- ✅ 用户存取款流程

### 待补充测试
- 🔄 非授权用户提取测试
- 🔄 用户取款功能测试
- 🔄 边界条件测试

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build
```shell
$ forge build
```

### Test
```shell
# 运行所有测试
$ forge test

# 运行特定测试
$ forge test --match-test testMinDepositRequirement

# 详细输出
$ forge test -v

# 超详细输出
$ forge test -vvv
```

### Format
```shell
$ forge fmt
```

### Gas Snapshots
```shell
$ forge snapshot
```

### Coverage
```shell
$ forge coverage
```

### Anvil
```shell
$ anvil
```

### Deploy
```shell
# 部署到本地网络
$ forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <your_private_key> --broadcast

# 部署到测试网
$ forge script script/Deploy.s.sol --rpc-url <testnet_rpc_url> --private-key <your_private_key> --broadcast --verify
```

### Cast
```shell
# 查询合约余额
$ cast balance <contract_address>

# 调用合约方法
$ cast call <contract_address> "balances(address)" <user_address>

# 发送交易
$ cast send <contract_address> "deposit()" --value 0.01ether --private-key <your_private_key>
```

### Help
```shell
$ forge --help
$ anvil --help
$ cast --help
```

## 快速开始

1. **克隆项目并进入目录**
```shell
cd /Users/youshuncheng/solidity/modoule2/BigBank
```

2. **编译合约**
```shell
forge build
```

3. **运行测试**
```shell
forge test
```

4. **启动本地节点**
```shell
anvil
```

5. **部署合约** (在另一个终端)
```shell
forge script script/Deploy.s.sol --rpc-url http://localhost:8545 --private-key <anvil_private_key> --broadcast
```

## 使用流程

### 系统初始化
1. 部署 BigBank 合约
2. 部署 Admin 合约
3. 将 BigBank 所有权转移给 Admin 合约

### 用户操作
1. 用户向 BigBank 存入 ETH (≥ 0.001 ETH)
2. 用户可以查询自己的余额
3. 用户可以取出自己的资金

### 管理员操作
1. 管理员可以提取银行所有资金到 Admin 合约
2. 管理员可以查询 Admin 合约的资金状况

## 注意事项

- 确保存款金额不少于 0.001 ETH
- 管理员操作需要正确的权限验证
- 建议在测试网络上充分测试后再部署到主网
- 注意 gas 费用的合理设置
