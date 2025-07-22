# Airdrop Distributor

## 概述

这是一个基于 Merkle Tree 的 ERC20 代币空投分发智能合约。它允许项目方高效、安全地向大量用户分发代币，同时最大限度地降低 Gas 成本。用户可以通过提供其在白名单中的资格证明（Merkle Proof）来领取指定数量的代币。

该合约基于 OpenZeppelin 的标准库构建，包含了 `Ownable`, `ReentrancyGuard`, `Pausable` 和 `SafeERC20` 等安全特性。

## 特性

- **Gas 高效**：通过链下生成 Merkle Tree，并将根哈希存储在链上，合约无需存储整个空投白名单，从而大大节省了部署和分发的 Gas 费用。
- **防止重复领取**：合约会记录每个地址的领取状态，确保每个符合资格的地址只能领取一次。
- **安全可靠**：
    - `ReentrancyGuard`: 防止重入攻击。
    - `Pausable`: 在紧急情况下，合约所有者可以暂停领取功能。
    - `Ownable`: 关键的管理功能仅限合约所有者执行。
    - `SafeERC20`: 使用安全的 ERC20 交互方式，避免了与非标准 ERC20 代币交互时可能出现的问题。
- **灵活管理**：合约所有者可以更新 Merkle Root（例如，开始新一轮空投），调整最大可领取总量，以及在空投结束后提取剩余的代币。

## 工作原理

1.  **链下准备**:
    -   项目方创建一个包含所有符合空投资格的地址及其对应代币数量的列表（例如，`whitelist.json`）。
    -   基于这个列表，使用脚本生成一个 Merkle Tree。
    -   将生成的 Merkle Tree 的根哈希（Merkle Root）记录下来。

2.  **合约部署**:
    -   部署 `AirdropDistributor` 合约时，需要提供要分发的 **ERC20 代币地址** 和链下生成的 **Merkle Root**。
    -   将需要空投的代币转入已部署的 `AirdropDistributor` 合约中。

3.  **用户领取**:
    -   用户访问空投领取页面（DApp）。
    -   DApp 根据用户的地址，从完整的白名单数据中找到对应的代币数量和生成 Merkle Proof 所需的数据。
    -   用户调用 `claimWithMerkle` 函数，并传入他们的地址、代币数量以及 Merkle Proof。
    -   合约通过 `MerkleProof.verify` 函数验证用户提供的证明是否有效。如果证明有效且该用户未领取过，合约将向用户地址发送指定数量的代币。

## 主要函数

### 用户函数

-   `claimWithMerkle(address to, uint256 amount, bytes32[] calldata proof)`: 用户调用此函数领取空投。需要提供接收地址、领取数量和 Merkle Proof。
-   `canClaim(address account, uint256 amount, bytes32[] calldata proof)`: 一个视图函数，用于检查某个地址是否可以领取指定数量的代币。

### 管理员函数 (仅限所有者)

-   `updateMerkleRoot(bytes32 _merkleRoot)`: 更新 Merkle Root。
-   `updateMaxClaimableAmount(uint256 _maxClaimableAmount)`: 更新最大可领取的代币总量。
-   `pause()` / `unpause()`: 暂停或恢复合约的领取功能。
-   `withdrawTokens(address to, uint256 amount)`: 提取合约中剩余的空投代币。
-   `emergencyWithdraw(address tokenAddress, address to, uint256 amount)`: 在紧急情况下，提取合约中存放的任意 ERC20 代币。

## 开发与测试 (Foundry)

### 构建

```shell
forge build
```

### 测试

```shell
forge test
```

### 格式化代码

```shell
forge fmt
```

### 部署示例

```shell
# 确保你的 .env 文件中包含了 RPC_URL 和 PRIVATE_KEY
forge script script/Deploy.s.sol:DeployScript --rpc-url $RPC_URL --private-key $PRIVATE_KEY --broadcast --verify
