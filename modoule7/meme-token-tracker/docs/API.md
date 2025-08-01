# 📡 API 使用文档

本文档详细说明了 Meme Token Tracker 的 API 使用方法、数据格式和集成示例。

## 📋 目录

- [快速开始](#快速开始)
- [数据模型](#数据模型)
- [Substreams 模块](#substreams-模块)
- [输出格式](#输出格式)
- [集成示例](#集成示例)
- [实时订阅](#实时订阅)
- [错误处理](#错误处理)
- [性能优化](#性能优化)

## 🚀 快速开始

### 基础调用

```bash
# 获取最新 100 个区块的 meme token 活跃度
substreams run \
  -e eth.streamingfast.io:443 \
  substreams.yaml \
  map_token_rankings \
  --start-block -100
```

### 指定区块范围

```bash
# 获取特定区块范围的数据
substreams run \
  -e eth.streamingfast.io:443 \
  substreams.yaml \
  map_token_rankings \
  --start-block 18000000 \
  --stop-block 18001000
```

### 实时流式数据

```bash
# 实时获取最新数据 (不指定结束区块)
substreams run \
  -e eth.streamingfast.io:443 \
  substreams.yaml \
  map_token_rankings \
  --start-block 19000000
```

## 📊 数据模型

### Protocol Buffers 定义

```protobuf
// proto/meme.proto

syntax = "proto3";
package meme;

// 单个转账事件
message TokenTransfer {
  string token_address = 1;     // Token 合约地址
  string from = 2;              // 发送方地址
  string to = 3;                // 接收方地址
  string amount = 4;            // 转账金额 (hex string)
  uint64 block_number = 5;      // 区块号
  string transaction_hash = 6;  // 交易哈希
  uint64 log_index = 7;         // 日志索引
}

// 转账事件集合
message TokenTransfers {
  repeated TokenTransfer transfers = 1;
}

// Token 活跃度统计
message TokenActivity {
  string address = 1;           // Token 地址
  uint64 transfer_count = 2;    // 转账次数
  uint64 last_block = 3;        // 最后活跃区块
  string symbol = 4;            // Token 符号
}

// 活跃度排行榜
message TokenRankings {
  repeated TokenActivity rankings = 1;  // 排行榜数据
  uint64 total_transfers = 2;           // 总转账次数
  uint64 block_range_start = 3;         // 起始区块
  uint64 block_range_end = 4;           // 结束区块
}
```

### 字段说明

#### TokenTransfer
| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `token_address` | string | ERC20 Token 合约地址 | `"0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce"` |
| `from` | string | 转账发送方地址 | `"0x1234...abcd"` |
| `to` | string | 转账接收方地址 | `"0x5678...efgh"` |
| `amount` | string | 转账金额 (16进制) | `"0x1bc16d674ec80000"` |
| `block_number` | uint64 | 区块号 | `19000123` |
| `transaction_hash` | string | 交易哈希 | `"0xabc123..."` |
| `log_index` | uint64 | 事件在交易中的索引 | `2` |

#### TokenActivity
| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `address` | string | Token 合约地址 | `"0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce"` |
| `transfer_count` | uint64 | 统计期间内转账次数 | `1247` |
| `last_block` | uint64 | 最后一次转账的区块号 | `19000085` |
| `symbol` | string | Token 符号 | `"SHIB"` |

#### TokenRankings
| 字段 | 类型 | 说明 | 示例 |
|------|------|------|------|
| `rankings` | TokenActivity[] | 按活跃度排序的 Token 列表 | `[{SHIB数据}, {PEPE数据}]` |
| `total_transfers` | uint64 | 所有 Token 的总转账次数 | `2847` |
| `block_range_start` | uint64 | 统计的起始区块 | `19000000` |
| `block_range_end` | uint64 | 统计的结束区块 | `19000100` |

## 🔧 Substreams 模块

### map_token_transfers

**功能**: 从以太坊区块中提取白名单 meme token 的转账事件

**输入**: `sf.ethereum.type.v2.Block`  
**输出**: `proto:meme.TokenTransfers`

**处理逻辑**:
1. 遍历区块中的所有交易
2. 检查交易回执中的日志事件
3. 过滤 ERC20 Transfer 事件 (`0xddf252ad...`)
4. 验证 Token 地址是否在白名单中
5. 解析 from, to, amount 字段
6. 组装 TokenTransfer 对象

**使用示例**:
```bash
substreams run \
  -e eth.streamingfast.io:443 \
  substreams.yaml \
  map_token_transfers \
  --start-block 19000000 \
  --stop-block 19000010
```

### map_token_rankings

**功能**: 基于转账数据生成 Token 活跃度排行榜

**输入**: `map: map_token_transfers`  
**输出**: `proto:meme.TokenRankings`

**处理逻辑**:
1. 接收 TokenTransfers 数据
2. 按 token_address 聚合转账次数
3. 记录每个 Token 的最后活跃区块
4. 按转账次数降序排序
5. 计算统计信息并输出

**使用示例**:
```bash
substreams run \
  -e eth.streamingfast.io:443 \
  substreams.yaml \
  map_token_rankings \
  --start-block 19000000 \
  --stop-block 19000010
```

## 📄 输出格式

### JSON 输出示例

#### 单个区块的 TokenTransfers
```json
{
  "transfers": [
    {
      "token_address": "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce",
      "from": "0x1234567890123456789012345678901234567890",
      "to": "0x0987654321098765432109876543210987654321",
      "amount": "0x1bc16d674ec80000",
      "block_number": "19000123",
      "transaction_hash": "0xabc123def456789...",
      "log_index": "2"
    },
    {
      "token_address": "0x6982508145454ce325ddbe47a25d4ec3d2311933",
      "from": "0x2222222222222222222222222222222222222222",
      "to": "0x3333333333333333333333333333333333333333",
      "amount": "0x56bc75e2d630eb20000",
      "block_number": "19000123",
      "transaction_hash": "0xdef456abc789012...",
      "log_index": "5"
    }
  ]
}
```

#### TokenRankings 输出
```json
{
  "rankings": [
    {
      "address": "0x95ad61b0a150d79219dcf64e1e6cc01f0b64c4ce",
      "transfer_count": "1247",
      "last_block": "19000085",
      "symbol": "SHIB"
    },
    {
      "address": "0x6982508145454ce325ddbe47a25d4ec3d2311933",
      "transfer_count": "892",
      "last_block": "19000082",
      "symbol": "PEPE"
    },
    {
      "address": "0x4d224452801aced8b2f0aebe155379bb5d594381",
      "transfer_count": "567",
      "last_block": "19000078",
      "symbol": "APE"
    },
    {
      "address": "0xba11d00c5f74255f56a5e366f4f77f5a186d7f55",
      "transfer_count": "234",
      "last_block": "19000075",
      "symbol": "BAND"
    },
    {
      "address": "0x853d955acef822db058eb8505911ed77f175b99e",
      "transfer_count": "123",
      "last_block": "19000071",
      "symbol": "FRAX"
    }
  ],
  "total_transfers": "3063",
  "block_range_start": "19000000",
  "block_range_end": "19000100"
}
```

### 输出格式说明

- **数字字段**: 以字符串形式输出，避免 JavaScript 大数精度问题
- **地址格式**: 统一小写，带 `0x` 前缀
- **金额格式**: 16进制字符串，需要客户端转换为 decimal
- **排序规则**: 按 `transfer_count` 降序排列

## 💻 集成示例

### Node.js 集成

```javascript
const { exec } = require('child_process');
const util = require('util');
const execPromise = util.promisify(exec);

class MemeTokenTracker {
  constructor(apiToken, endpoint = 'eth.streamingfast.io:443') {
    this.apiToken = apiToken;
    this.endpoint = endpoint;
    
    // 设置环境变量
    process.env.SUBSTREAMS_API_TOKEN = apiToken;
  }

  /**
   * 获取指定区块范围的 Token 活跃度排行
   * @param {number} startBlock - 起始区块
   * @param {number} stopBlock - 结束区块 (可选)
   * @returns {Promise<Object>} Token 排行榜数据
   */
  async getTokenRankings(startBlock, stopBlock = null) {
    let command = `substreams run -e ${this.endpoint} substreams.yaml map_token_rankings --start-block ${startBlock} --output jsonl`;
    
    if (stopBlock) {
      command += ` --stop-block ${stopBlock}`;
    }

    try {
      const { stdout } = await execPromise(command);
      
      // 解析最后一行输出 (最终结果)
      const lines = stdout.trim().split('\n');
      const lastLine = lines[lines.length - 1];
      
      return JSON.parse(lastLine);
    } catch (error) {
      throw new Error(`Failed to get token rankings: ${error.message}`);
    }
  }

  /**
   * 获取实时 Token 活跃度数据
   * @param {number} startBlock - 起始区块
   * @param {Function} onData - 数据回调函数
   * @param {Function} onError - 错误回调函数
   */
  streamTokenRankings(startBlock, onData, onError) {
    const command = `substreams run -e ${this.endpoint} substreams.yaml map_token_rankings --start-block ${startBlock} --output jsonl`;
    
    const child = exec(command);
    
    child.stdout.on('data', (data) => {
      const lines = data.toString().split('\n');
      lines.forEach(line => {
        if (line.trim()) {
          try {
            const ranking = JSON.parse(line);
            onData(ranking);
          } catch (e) {
            // 忽略解析错误的行
          }
        }
      });
    });

    child.stderr.on('data', (data) => {
      onError(new Error(data.toString()));
    });

    child.on('exit', (code) => {
      if (code !== 0) {
        onError(new Error(`Process exited with code ${code}`));
      }
    });

    return child;
  }

  /**
   * 转换金额格式 (hex -> decimal)
   * @param {string} hexAmount - 16进制金额字符串
   * @param {number} decimals - Token 精度 (默认18)
   * @returns {string} 十进制金额字符串
   */
  static formatAmount(hexAmount, decimals = 18) {
    const BigNumber = require('bignumber.js');
    const amount = new BigNumber(hexAmount, 16);
    return amount.dividedBy(new BigNumber(10).pow(decimals)).toString();
  }
}

// 使用示例
async function example() {
  const tracker = new MemeTokenTracker('your_api_token_here');
  
  try {
    // 获取最近 1000 个区块的数据
    const rankings = await tracker.getTokenRankings(-1000);
    console.log('Top 3 most active meme tokens:');
    rankings.rankings.slice(0, 3).forEach((token, index) => {
      console.log(`${index + 1}. ${token.symbol}: ${token.transfer_count} transfers`);
    });

    // 实时监控
    console.log('Starting real-time monitoring...');
    tracker.streamTokenRankings(-100, 
      (data) => {
        console.log(`Updated rankings at block ${data.block_range_end}`);
        console.log(`Total transfers: ${data.total_transfers}`);
      },
      (error) => {
        console.error('Stream error:', error.message);
      }
    );
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

module.exports = MemeTokenTracker;
```

### Python 集成

```python
import subprocess
import json
import os
from typing import Dict, List, Optional, Callable
from decimal import Decimal

class MemeTokenTracker:
    def __init__(self, api_token: str, endpoint: str = 'eth.streamingfast.io:443'):
        self.api_token = api_token
        self.endpoint = endpoint
        
        # 设置环境变量
        os.environ['SUBSTREAMS_API_TOKEN'] = api_token

    def get_token_rankings(self, start_block: int, stop_block: Optional[int] = None) -> Dict:
        """获取指定区块范围的 Token 活跃度排行"""
        command = [
            'substreams', 'run',
            '-e', self.endpoint,
            'substreams.yaml',
            'map_token_rankings',
            '--start-block', str(start_block),
            '--output', 'jsonl'
        ]
        
        if stop_block:
            command.extend(['--stop-block', str(stop_block)])

        try:
            result = subprocess.run(command, capture_output=True, text=True, check=True)
            
            # 解析最后一行输出
            lines = result.stdout.strip().split('\n')
            last_line = lines[-1] if lines else '{}'
            
            return json.loads(last_line)
            
        except subprocess.CalledProcessError as e:
            raise Exception(f"Failed to get token rankings: {e.stderr}")
        except json.JSONDecodeError as e:
            raise Exception(f"Failed to parse JSON response: {e}")

    def stream_token_rankings(self, start_block: int, on_data: Callable, on_error: Callable):
        """实时流式获取 Token 活跃度数据"""
        command = [
            'substreams', 'run',
            '-e', self.endpoint,
            'substreams.yaml',
            'map_token_rankings',
            '--start-block', str(start_block),
            '--output', 'jsonl'
        ]

        try:
            process = subprocess.Popen(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                bufsize=1,
                universal_newlines=True
            )

            for line in iter(process.stdout.readline, ''):
                line = line.strip()
                if line:
                    try:
                        data = json.loads(line)
                        on_data(data)
                    except json.JSONDecodeError:
                        # 忽略解析错误的行
                        continue

            # 检查进程是否有错误
            if process.returncode and process.returncode != 0:
                stderr = process.stderr.read()
                on_error(Exception(f"Process error: {stderr}"))

        except Exception as e:
            on_error(e)

    @staticmethod
    def format_amount(hex_amount: str, decimals: int = 18) -> str:
        """转换金额格式 (hex -> decimal)"""
        amount = int(hex_amount, 16)
        return str(Decimal(amount) / Decimal(10 ** decimals))

    def get_top_tokens(self, start_block: int, limit: int = 5) -> List[Dict]:
        """获取最活跃的 Token 列表"""
        rankings = self.get_token_rankings(start_block)
        return rankings.get('rankings', [])[:limit]

# 使用示例
def main():
    tracker = MemeTokenTracker('your_api_token_here')
    
    try:
        # 获取最近 1000 个区块的数据
        rankings = tracker.get_token_rankings(-1000)
        print(f"Total transfers in range: {rankings['total_transfers']}")
        print(f"Block range: {rankings['block_range_start']} - {rankings['block_range_end']}")
        
        print("\nTop 5 most active meme tokens:")
        for i, token in enumerate(rankings['rankings'][:5], 1):
            print(f"{i}. {token['symbol']}: {token['transfer_count']} transfers")

        # 实时监控示例
        def on_data(data):
            print(f"📊 Updated at block {data['block_range_end']}")
            if data['rankings']:
                top_token = data['rankings'][0]
                print(f"🏆 Most active: {top_token['symbol']} ({top_token['transfer_count']} transfers)")

        def on_error(error):
            print(f"❌ Error: {error}")

        print("\n🔄 Starting real-time monitoring...")
        tracker.stream_token_rankings(-100, on_data, on_error)
        
    except Exception as e:
        print(f"Error: {e}")

if __name__ == "__main__":
    main()
```

### REST API 包装器

```javascript
// Express.js API 服务器
const express = require('express');
const MemeTokenTracker = require('./meme-token-tracker');

const app = express();
const tracker = new MemeTokenTracker(process.env.SUBSTREAMS_API_TOKEN);

// 获取 Token 排行榜
app.get('/api/rankings', async (req, res) => {
  try {
    const startBlock = parseInt(req.query.start_block) || -1000;
    const stopBlock = req.query.stop_block ? parseInt(req.query.stop_block) : null;
    
    const rankings = await tracker.getTokenRankings(startBlock, stopBlock);
    
    res.json({
      success: true,
      data: rankings,
      timestamp: new Date().toISOString()
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 获取单个 Token 信息
app.get('/api/token/:address', async (req, res) => {
  try {
    const address = req.params.address.toLowerCase();
    const rankings = await tracker.getTokenRankings(-1000);
    
    const token = rankings.rankings.find(t => t.address === address);
    
    if (!token) {
      return res.status(404).json({
        success: false,
        error: 'Token not found'
      });
    }
    
    res.json({
      success: true,
      data: token
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      error: error.message
    });
  }
});

// 健康检查
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Meme Token Tracker API running on port ${PORT}`);
});
```

## 🔄 实时订阅

### WebSocket 实现

```javascript
const WebSocket = require('ws');
const MemeTokenTracker = require('./meme-token-tracker');

const wss = new WebSocket.Server({ port: 8080 });
const tracker = new MemeTokenTracker(process.env.SUBSTREAMS_API_TOKEN);

wss.on('connection', (ws) => {
  console.log('New WebSocket connection');
  
  // 开始实时数据流
  const child = tracker.streamTokenRankings(-100, 
    (data) => {
      // 发送数据到客户端
      ws.send(JSON.stringify({
        type: 'ranking_update',
        data: data,
        timestamp: new Date().toISOString()
      }));
    },
    (error) => {
      ws.send(JSON.stringify({
        type: 'error',
        message: error.message,
        timestamp: new Date().toISOString()
      }));
    }
  );

  ws.on('close', () => {
    console.log('WebSocket connection closed');
    child.kill(); // 停止数据流
  });
});

console.log('WebSocket server running on port 8080');
```

### 客户端订阅示例

```html
<!DOCTYPE html>
<html>
<head>
    <title>Meme Token Tracker Live</title>
</head>
<body>
    <h1>🚀 Meme Token Live Rankings</h1>
    <div id="rankings"></div>

    <script>
        const ws = new WebSocket('ws://localhost:8080');
        
        ws.onmessage = (event) => {
            const message = JSON.parse(event.data);
            
            if (message.type === 'ranking_update') {
                updateRankings(message.data);
            } else if (message.type === 'error') {
                console.error('Error:', message.message);
            }
        };

        function updateRankings(data) {
            const rankingsDiv = document.getElementById('rankings');
            
            let html = `
                <h2>Block Range: ${data.block_range_start} - ${data.block_range_end}</h2>
                <p>Total Transfers: ${data.total_transfers}</p>
                <ol>
            `;
            
            data.rankings.forEach(token => {
                html += `
                    <li>
                        <strong>${token.symbol}</strong>: 
                        ${token.transfer_count} transfers 
                        (last active: block ${token.last_block})
                    </li>
                `;
            });
            
            html += '</ol>';
            rankingsDiv.innerHTML = html;
        }

        ws.onopen = () => console.log('Connected to WebSocket');
        ws.onclose = () => console.log('Disconnected from WebSocket');
        ws.onerror = (error) => console.error('WebSocket error:', error);
    </script>
</body>
</html>
```

## ❌ 错误处理

### 常见错误类型

| 错误类型 | 原因 | 解决方案 |
|----------|------|----------|
| `Authentication failed` | API Token 无效或过期 | 检查并更新 `SUBSTREAMS_API_TOKEN` |
| `Block not found` | 区块号不存在 | 检查区块号是否在有效范围内 |
| `Network timeout` | 网络连接超时 | 增加超时时间或检查网络连接 |
| `Rate limit exceeded` | 请求频率过高 | 降低请求频率或升级 API 计划 |
| `Invalid module` | 模块名称错误 | 检查 `substreams.yaml` 配置 |

### 错误处理示例

```javascript
class SubstreamsError extends Error {
  constructor(message, type, details = {}) {
    super(message);
    this.name = 'SubstreamsError';
    this.type = type;
    this.details = details;
  }
}

async function safeGetRankings(tracker, startBlock, maxRetries = 3) {
  let lastError;
  
  for (let i = 0; i < maxRetries; i++) {
    try {
      return await tracker.getTokenRankings(startBlock);
    } catch (error) {
      lastError = error;
      
      // 根据错误类型决定是否重试
      if (error.message.includes('rate limit')) {
        await new Promise(resolve => setTimeout(resolve, 5000 * (i + 1))); // 指数退避
        continue;
      } else if (error.message.includes('timeout')) {
        await new Promise(resolve => setTimeout(resolve, 1000 * (i + 1)));
        continue;
      } else {
        // 不可重试的错误
        break;
      }
    }
  }
  
  throw new SubstreamsError(
    `Failed to get rankings after ${maxRetries} retries: ${lastError.message}`,
    'MAX_RETRIES_EXCEEDED',
    { originalError: lastError }
  );
}
```

## ⚡ 性能优化

### 1. 区块范围优化

```javascript
// 避免过大的区块范围
const OPTIMAL_BLOCK_RANGE = 1000;

function getOptimalBlockRange(startBlock, endBlock) {
  const range = endBlock - startBlock;
  if (range > OPTIMAL_BLOCK_RANGE) {
    // 分批处理
    const batches = [];
    for (let i = startBlock; i < endBlock; i += OPTIMAL_BLOCK_RANGE) {
      batches.push({
        start: i,
        end: Math.min(i + OPTIMAL_BLOCK_RANGE, endBlock)
      });
    }
    return batches;
  }
  return [{ start: startBlock, end: endBlock }];
}
```

### 2. 缓存策略

```javascript
const NodeCache = require('node-cache');
const cache = new NodeCache({ stdTTL: 60 }); // 1分钟缓存

async function getCachedRankings(tracker, startBlock, stopBlock) {
  const cacheKey = `rankings_${startBlock}_${stopBlock || 'live'}`;
  
  // 尝试从缓存获取
  const cached = cache.get(cacheKey);
  if (cached) {
    return cached;
  }
  
  // 获取新数据并缓存
  const rankings = await tracker.getTokenRankings(startBlock, stopBlock);
  cache.set(cacheKey, rankings);
  
  return rankings;
}
```

### 3. 连接池管理

```javascript
class SubstreamsPool {
  constructor(apiToken, maxConnections = 5) {
    this.apiToken = apiToken;
    this.maxConnections = maxConnections;
    this.activeConnections = 0;
    this.queue = [];
  }

  async execute(operation) {
    return new Promise((resolve, reject) => {
      this.queue.push({ operation, resolve, reject });
      this.processQueue();
    });
  }

  async processQueue() {
    if (this.activeConnections >= this.maxConnections || this.queue.length === 0) {
      return;
    }

    const { operation, resolve, reject } = this.queue.shift();
    this.activeConnections++;

    try {
      const result = await operation();
      resolve(result);
    } catch (error) {
      reject(error);
    } finally {
      this.activeConnections--;
      this.processQueue();
    }
  }
}
```

---

**📘 这份 API 文档为您提供了完整的集成指南。如有疑问，请查看示例代码或联系技术支持。**