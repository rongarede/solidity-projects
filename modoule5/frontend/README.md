# ReadLock Frontend - Viem Storage Reader

使用Viem框架读取ReadLock合约存储数据的前端应用。

## 功能特性

- 🔍 使用Viem的`getStorageAt`直接读取合约存储
- 📊 解析和显示`_locks`数组中的所有锁仓信息
- 🌐 美观的Web界面显示数据
- 📱 响应式设计，支持移动端
- 🔄 支持数据刷新和实时更新

## 项目结构

```
frontend/
├── src/
│   ├── storage-reader.js    # Node.js存储读取脚本
│   └── web-client.js        # 浏览器端客户端脚本
├── public/
│   └── index.html           # 主页面
├── package.json
├── vite.config.js
└── README.md
```

## 安装和运行

### 1. 确保本地网络运行
```bash
# 在ReadLock目录下启动本地网络
cd ../ReadLock
anvil
```

### 2. 部署合约
```bash
# 在ReadLock目录下部署合约
forge script script/ReadLock.s.sol:ReadLockScript --rpc-url http://127.0.0.1:8545 --private-key 0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80 --broadcast
```

### 3. 启动前端应用
```bash
# 在frontend目录下
npm install
npm run dev
```

### 4. 使用Node.js脚本
```bash
# 直接运行存储读取脚本
npm run start
```

## 使用说明

### Web界面
1. 打开浏览器访问 `http://localhost:3000`
2. 点击"读取锁仓数据"按钮
3. 查看解析后的锁仓信息

### Node.js脚本
直接运行脚本会在控制台输出所有锁仓信息：
```
locks[0]: user: 0x0000000000000000000000000000000000000001, startTime: 2024-07-16 10:30:15, amount: 1.0 ETH
locks[1]: user: 0x0000000000000000000000000000000000000002, startTime: 2024-07-16 10:30:14, amount: 2.0 ETH
...
```

## 技术实现

### 存储槽位计算
- 动态数组长度存储在槽位0
- 数组数据从`keccak256(0)`开始存储
- 每个`LockInfo`结构体占用2个槽位

### 数据解析
- 槽位1: `address user` (20字节) + `uint64 startTime` (8字节)
- 槽位2: `uint256 amount` (32字节)

### 关键功能
- `getStorageAt()`: 读取指定槽位数据
- `calculateArraySlot()`: 计算动态数组存储位置
- `parseLockInfo()`: 解析结构体数据
- `formatAmount()`: 格式化金额显示
- `formatTimestamp()`: 格式化时间显示

## 配置

### 网络配置
- RPC URL: `http://127.0.0.1:8545`
- Chain ID: `31337`
- 合约地址: `0x5FbDB2315678afecb367f032d93F642f64180aa3`

### 修改合约地址
如果重新部署了合约，请更新以下文件中的合约地址：
- `src/web-client.js`: 修改`CONTRACT_ADDRESS`常量
- `src/storage-reader.js`: 修改`getContractAddress()`函数的默认返回值

## 故障排除

1. **无法连接到RPC**: 确保anvil正在运行并监听8545端口
2. **读取失败**: 检查合约是否正确部署
3. **数据解析错误**: 确认合约结构体定义与解析逻辑匹配

## 扩展功能

- 支持更多合约地址
- 添加数据导出功能
- 实现WebSocket实时更新
- 添加图表可视化