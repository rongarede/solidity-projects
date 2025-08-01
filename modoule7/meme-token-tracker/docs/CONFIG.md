# 📖 配置说明文档

本文档详细说明了 Meme Token Tracker 的所有配置选项和自定义方法。

## 📋 目录

- [基础配置](#基础配置)
- [Substreams 配置](#substreams-配置)
- [环境变量](#环境变量)
- [Token 白名单配置](#token-白名单配置)
- [网络配置](#网络配置)
- [性能调优](#性能调优)
- [故障排除](#故障排除)

## 🚀 基础配置

### 1. API Token 配置

获取 StreamingFast API Token：

```bash
# 方法1: 环境变量
export SUBSTREAMS_API_TOKEN="your_token_here"

# 方法2: .env 文件
echo "SUBSTREAMS_API_TOKEN=your_token_here" > .env

# 方法3: 配置文件
substreams auth
```

### 2. 快速配置验证

```bash
# 验证 API Token
substreams auth

# 验证配置文件
substreams validate substreams.yaml

# 测试连接
substreams run -e eth.streamingfast.io:443 \
  substreams.yaml map_token_transfers \
  --start-block -1 --stop-block +1
```

## ⚙️ Substreams 配置

### substreams.yaml 详解

```yaml
specVersion: v0.1.0
package:
  name: "meme-token-tracker"
  version: v0.1.0
  url: "https://github.com/your-username/meme-token-tracker"
  doc: "Ethereum Meme Token Activity Tracker using Substreams"

# 导入依赖
imports:
  ethereum: https://github.com/streamingfast/substreams-ethereum/releases/download/v0.9.13/substreams-ethereum-v0.9.13.spkg

# Protobuf 定义
protobuf:
  files:
    - proto/meme.proto
  importPaths:
    - ./proto

# WebAssembly 二进制文件
binaries:
  default:
    type: wasm/rust-v1
    file: ./target/wasm32-unknown-unknown/release/substreams.wasm

# 处理模块
modules:
  - name: map_token_transfers
    kind: map
    initialBlock: 17000000  # 配置起始区块
    inputs:
      - source: sf.ethereum.type.v2.Block
    output:
      type: proto:meme.TokenTransfers
    doc: "Extract ERC20 Transfer events for whitelisted meme tokens"

  - name: map_token_rankings
    kind: map
    initialBlock: 17000000
    inputs:
      - map: map_token_transfers
    output:
      type: proto:meme.TokenRankings
    doc: "Generate token activity rankings based on transfer counts"

# 网络配置
network: mainnet

# 参数配置
params:
  endpoint: "eth.streamingfast.io:443"
  start_block: 17000000
  timeout: "300s"
  retry_count: 3
```

### 配置选项说明

| 配置项 | 说明 | 可选值 | 默认值 |
|--------|------|--------|--------|
| `initialBlock` | 模块开始处理的区块号 | 任意有效区块号 | `17000000` |
| `network` | 目标网络 | `mainnet`, `goerli`, `sepolia` | `mainnet` |
| `endpoint` | Substreams 端点 | StreamingFast 端点 | `eth.streamingfast.io:443` |
| `timeout` | 请求超时时间 | 时间字符串 | `300s` |
| `retry_count` | 重试次数 | 正整数 | `3` |

## 🌍 环境变量

### 核心环境变量

```bash
# 必需的环境变量
export SUBSTREAMS_API_TOKEN="your_streamingfast_api_token"

# 可选的环境变量
export SUBSTREAMS_ENDPOINT="eth.streamingfast.io:443"
export START_BLOCK="17000000"
export STOP_BLOCK="+1000"
export SUBSTREAMS_DEBUG="false"
export RUST_LOG="info"
```

### 环境变量详解

#### `SUBSTREAMS_API_TOKEN` (必需)
```bash
# 从 StreamingFast 获取的 API Token
export SUBSTREAMS_API_TOKEN="sf_api_key_xxxxxxxxxxxxxxxxxxxxxxxx"
```

#### `SUBSTREAMS_ENDPOINT` (可选)
```bash
# Ethereum 主网
export SUBSTREAMS_ENDPOINT="eth.streamingfast.io:443"

# Ethereum Goerli 测试网
export SUBSTREAMS_ENDPOINT="goerli.eth.streamingfast.io:443"

# Polygon 主网
export SUBSTREAMS_ENDPOINT="polygon.streamingfast.io:443"
```

#### `START_BLOCK` / `STOP_BLOCK` (可选)
```bash
# 绝对区块号
export START_BLOCK="18000000"
export STOP_BLOCK="18001000"

# 相对区块号
export START_BLOCK="-100"    # 最新区块往前100个
export STOP_BLOCK="+1000"    # 从起始区块开始1000个区块
```

#### `RUST_LOG` (调试)
```bash
# 日志级别
export RUST_LOG="error"    # 仅错误
export RUST_LOG="warn"     # 警告及以上
export RUST_LOG="info"     # 信息及以上 (推荐)
export RUST_LOG="debug"    # 调试及以上
export RUST_LOG="trace"    # 所有日志
```

## 🎯 Token 白名单配置

### 当前白名单

```rust
pub const MEME_TOKENS: &[&str] = &[
    "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce", // SHIB
    "0x6982508145454ce325ddbe47a25d4ec3d2311933", // PEPE
    "0xba11d00c5f74255f56a5e366f4f77f5a186d7f55", // BAND
    "0x4d224452801aced8b2f0aebe155379bb5d594381", // APE
    "0x853d955acef822db058eb8505911ed77f175b99e", // FRAX
];
```

### 自定义白名单

1. **编辑源代码** (推荐用于开发)

```rust
// 在 src/lib.rs 中修改
const MEME_TOKENS: &[&str] = &[
    "0x1234567890123456789012345678901234567890", // YOUR_TOKEN
    "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce", // SHIB
    // ... 添加更多 Token
];
```

2. **配置文件方式** (推荐用于生产)

创建 `config.toml`:
```toml
[tokens]
whitelist = [
    { address = "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce", symbol = "SHIB" },
    { address = "0x6982508145454ce325ddbe47a25d4ec3d2311933", symbol = "PEPE" },
    # 添加新的 Token
    { address = "0xYourTokenAddress", symbol = "YOUR_TOKEN" }
]
```

3. **验证 Token 地址**

```bash
# 验证地址格式
echo "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce" | grep -E "^0x[a-fA-F0-9]{40}$"

# 验证地址在链上存在
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_getCode","params":["0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce","latest"],"id":1}' \
  https://ethereum.publicnode.com
```

## 🌐 网络配置

### 支持的网络

| 网络 | 端点 | 配置 |
|------|------|------|
| Ethereum 主网 | `eth.streamingfast.io:443` | `network: mainnet` |
| Ethereum Goerli | `goerli.eth.streamingfast.io:443` | `network: goerli` |
| Polygon 主网 | `polygon.streamingfast.io:443` | `network: polygon` |
| BSC 主网 | `bsc.streamingfast.io:443` | `network: bsc` |

### 网络切换

1. **修改 substreams.yaml**
```yaml
network: goerli  # 改为目标网络
```

2. **更新环境变量**
```bash
export SUBSTREAMS_ENDPOINT="goerli.eth.streamingfast.io:443"
```

3. **调整起始区块**
```yaml
modules:
  - name: map_token_transfers
    initialBlock: 7000000  # Goerli 较新，区块号较小
```

## ⚡ 性能调优

### 区块范围优化

```bash
# 小范围测试 (快速验证)
--start-block 19000000 --stop-block 19000100

# 中等范围 (数据分析)
--start-block 18000000 --stop-block 18010000

# 大范围 (生产环境)
--start-block 17000000  # 不指定结束区块，持续运行
```

### 并发配置

```bash
# 调整并发处理
export SUBSTREAMS_PARALLEL_JOBS=4

# 调整缓冲区大小
export SUBSTREAMS_BUFFER_SIZE=1000
```

### 内存优化

```yaml
# 在 substreams.yaml 中添加
params:
  memory_limit: "512MB"
  cache_size: "100MB"
```

## 🔧 高级配置

### 1. 自定义 ERC20 事件

```rust
// 支持其他 ERC20 事件
const TRANSFER_EVENT_SIG: &str = "0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef";
const APPROVAL_EVENT_SIG: &str = "0x8c5be1e5ebec7d5bd14f71427d1e84f3dd0314c0f7b2291e5b200ac8c7c3b925";
```

### 2. 输出格式定制

修改 `proto/meme.proto`:
```protobuf
message TokenActivity {
  string address = 1;
  string symbol = 2;
  uint64 transfer_count = 3;
  uint64 last_block = 4;
  // 添加自定义字段
  uint64 total_volume = 5;
  uint64 unique_addresses = 6;
}
```

### 3. 过滤条件自定义

```rust
// 添加金额过滤
fn should_include_transfer(amount: &str) -> bool {
    // 只包含大于 1000 的转账
    amount.parse::<u64>().unwrap_or(0) > 1000
}
```

## 🚨 故障排除

### 常见错误及解决方案

#### 1. "Authentication failed"
```bash
# 检查 API Token
echo $SUBSTREAMS_API_TOKEN

# 重新认证
substreams auth
```

#### 2. "Block not found"
```bash
# 检查区块号是否有效
curl -X POST -H "Content-Type: application/json" \
  --data '{"jsonrpc":"2.0","method":"eth_blockNumber","params":[],"id":1}' \
  https://ethereum.publicnode.com
```

#### 3. "WASM execution failed"
```bash
# 重新构建 WASM
cargo clean
cargo build --release --target wasm32-unknown-unknown

# 检查 WASM 文件
file target/wasm32-unknown-unknown/release/substreams.wasm
```

#### 4. "Too many requests"
```bash
# 减少并发或添加延迟
export SUBSTREAMS_RATE_LIMIT=10  # 每秒10个请求
```

### 调试技巧

#### 1. 启用详细日志
```bash
export RUST_LOG=debug
export SUBSTREAMS_DEBUG=true
```

#### 2. 单区块测试
```bash
substreams run -e eth.streamingfast.io:443 \
  substreams.yaml map_token_transfers \
  --start-block 19000000 --stop-block 19000001
```

#### 3. 验证配置
```bash
# 验证 YAML 语法
yamllint substreams.yaml

# 验证 Protobuf
protoc --proto_path=proto --decode_raw < proto/meme.proto
```

## 📊 监控和日志

### 1. 性能监控

```bash
# 实时监控内存使用
watch 'ps aux | grep substreams'

# 监控网络连接
netstat -an | grep 443
```

### 2. 日志配置

```bash
# 输出到文件
substreams run ... 2>&1 | tee substreams.log

# 结构化日志
export RUST_LOG_FORMAT=json
export RUST_LOG=info
```

### 3. 指标收集

```rust
// 在代码中添加指标
log::info!("Processed {} transfers in block {}", count, block_number);
```

## 🔐 安全配置

### 1. API Token 安全

```bash
# 使用文件权限保护
chmod 600 .env

# 避免在命令行中暴露
export SUBSTREAMS_API_TOKEN=$(cat ~/.substreams_token)
```

### 2. 网络安全

```bash
# 使用 TLS
export SUBSTREAMS_ENDPOINT="eth.streamingfast.io:443"  # 注意 443 端口

# 验证证书
openssl s_client -connect eth.streamingfast.io:443 -servername eth.streamingfast.io
```

## 📚 配置模板

### 开发环境
```yaml
# substreams.dev.yaml
network: goerli
modules:
  - name: map_token_transfers
    initialBlock: 7000000
params:
  timeout: "60s"
  retry_count: 1
```

### 生产环境
```yaml
# substreams.prod.yaml
network: mainnet
modules:
  - name: map_token_transfers
    initialBlock: 17000000
params:
  timeout: "300s"
  retry_count: 5
  memory_limit: "1GB"
```

### 测试环境
```yaml
# substreams.test.yaml
network: mainnet
modules:
  - name: map_token_transfers
    initialBlock: 19000000
params:
  timeout: "30s"
  retry_count: 0
```

## 📞 获取帮助

如果遇到配置问题：

1. 查看 [故障排除](#故障排除) 部分
2. 检查 [StreamingFast 文档](https://substreams.streamingfast.io/)
3. 创建 [Issue](../../issues) 报告问题
4. 加入社区讨论

---

**💡 提示**: 配置变更后记得重新构建项目并运行测试验证。