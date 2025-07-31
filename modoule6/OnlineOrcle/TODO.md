# 简化版 TWAP Oracle 测试工具

## 项目概述
基于 Polygon 网络上的 Uniswap V2 DAI/WMATIC 交易对实现一个简单的 TWAP 价格查询测试工具

## 设计目标
- **简单易懂**：核心代码 < 150 行
- **快速实现**：专注 TWAP 计算逻辑验证
- **测试导向**：便于理解和调试 TWAP 机制

## 实现计划

### 阶段一：基础合约结构
- [ ] 1.1 创建简化接口 `ISimpleTWAP`
- [ ] 1.2 定义基础数据结构 `Observation`
- [ ] 1.3 设置 Uniswap V2 Pair 常量和配置
- [ ] 1.4 实现基础的 owner 权限控制

### 阶段二：核心 TWAP 逻辑
- [ ] 2.1 实现价格观察数据获取
- [ ] 2.2 实现两点式 TWAP 计算
- [ ] 2.3 添加价格更新函数 `update()`
- [ ] 2.4 实现价格查询函数 `getPrice()`

### 阶段三：测试和验证
- [ ] 3.1 编写基础部署脚本
- [ ] 3.2 创建简单的测试用例
- [ ] 3.3 验证与实际 Uniswap 数据的一致性

## 技术规格

### 目标交易对 (Polygon 网络)
- **网络**: Polygon (Chain ID: 137)
- **Factory**: 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f (Uniswap V2 Factory)
- **DAI**: 0x8f3cf7ad23cd3cadbd9735aff958023239c6a063 (PoS Dai Stablecoin)
- **WMATIC**: 0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270 (Wrapped Polygon/MATIC)
- **交易对地址**: 通过 Factory.getPair(DAI, WMATIC) 获取

### 简化配置
- **时间窗口**: 固定 30 分钟 (1800 秒)
- **精度**: 18 decimals
- **更新方式**: 手动调用 `update()`

### 合约接口设计

```solidity
interface ISimpleTWAP {
    // 获取当前 TWAP 价格 (DAI per WMATIC)
    function getPrice() external view returns (uint256);
    
    // 手动更新价格观察数据
    function update() external;
    
    // 获取最后更新时间
    function lastUpdateTime() external view returns (uint256);
    
    // 检查是否有足够的数据计算 TWAP
    function canComputeTWAP() external view returns (bool);
    
    // 事件：价格更新
    event PriceUpdated(uint256 price, uint256 timestamp);
}
```

### 核心数据结构

```solidity
struct Observation {
    uint256 timestamp;           // 观察时间戳
    uint256 price0Cumulative;    // DAI 累积价格
}

contract SimpleTWAPOracle {
    // Uniswap V2 Factory on Polygon
    address public constant FACTORY = 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f;
    
    // Token addresses on Polygon
    address public constant DAI = 0x8f3cf7ad23cd3cadbd9735aff958023239c6a063;
    address public constant WMATIC = 0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270;
    
    // DAI/WMATIC Pair (calculated via factory.getPair())
    
    // 30 分钟时间窗口
    uint256 public constant TIME_WINDOW = 1800;
    
    // 两个观察点用于计算 TWAP
    Observation public firstObservation;   // 较早的观察点
    Observation public secondObservation;  // 较新的观察点
    
    // 合约所有者
    address public owner;
    
    // 当前缓存的 TWAP 价格
    uint256 public cachedPrice;
}
```

## TWAP 计算公式

```
TWAP = (price0CumulativeEnd - price0CumulativeStart) / (timeEnd - timeStart)

其中：
- price0CumulativeEnd: 当前 DAI 累积价格
- price0CumulativeStart: 时间窗口开始时的 DAI 累积价格  
- timeEnd: 当前时间戳
- timeStart: 时间窗口开始时间戳
- 结果: DAI per WMATIC 的 TWAP 价格
```

## 实现步骤详解

### 第一步：获取交易对地址和数据
```solidity
function _getPairAddress() internal view returns (address) {
    return IUniswapV2Factory(FACTORY).getPair(DAI, WMATIC);
}

function _getCurrentData() internal view returns (uint256, uint32) {
    address pairAddress = _getPairAddress();
    require(pairAddress != address(0), "Pair does not exist");
    
    IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
    
    uint256 price0Cumulative = pair.price0CumulativeLast();
    (, , uint32 blockTimestampLast) = pair.getReserves();
    
    return (price0Cumulative, blockTimestampLast);
}
```

### 第二步：更新观察数据
```solidity
function update() external {
    (uint256 price0Cumulative, uint32 blockTimestamp) = _getCurrentData();
    
    // 如果是第一次更新，初始化两个观察点
    if (firstObservation.timestamp == 0) {
        firstObservation = Observation(blockTimestamp, price0Cumulative);
        secondObservation = firstObservation;
        return;
    }
    
    // 移动时间窗口
    if (blockTimestamp - firstObservation.timestamp >= TIME_WINDOW) {
        firstObservation = secondObservation;
    }
    
    secondObservation = Observation(blockTimestamp, price0Cumulative);
    
    // 计算并缓存新的 TWAP 价格
    if (canComputeTWAP()) {
        cachedPrice = _computeTWAP();
        emit PriceUpdated(cachedPrice, blockTimestamp);
    }
}
```

### 第三步：计算 TWAP
```solidity
function _computeTWAP() internal view returns (uint256) {
    uint256 timeElapsed = secondObservation.timestamp - firstObservation.timestamp;
    uint256 priceChange = secondObservation.price0Cumulative - firstObservation.price0Cumulative;
    
    return priceChange / timeElapsed;
}
```

## 测试策略

### 单元测试
- 测试数据获取函数
- 测试 TWAP 计算逻辑
- 测试边界条件处理

### 集成测试  
- 连接真实 Uniswap V2 Pair
- 验证价格数据准确性
- 测试时间窗口移动逻辑

### 部署测试
- 部署到 Polygon 主网或 Polygon Mumbai 测试网
- 验证 DAI/WMATIC 交易对存在性
- 执行多次更新验证 TWAP 计算
- 对比链下计算结果和 Polygon 实际价格

## Polygon 部署优势

### 成本效益
- **低 Gas 费用**: Polygon 交易费用比以太坊主网低 99%+
- **快速确认**: 2秒区块时间，快速测试迭代
- **开发友好**: 完全兼容 Ethereum 工具链

### 技术优势  
- **相同的 Uniswap V2 合约**: 代码逻辑完全一致
- **丰富的流动性**: DAI/WMATIC 有充足的交易对流动性
- **稳定的网络**: Polygon 网络稳定，适合测试和生产

### 获取交易对地址方法
```bash
# 使用 cast 命令查询交易对地址
cast call 0x5C69bEe701ef814a2B6a3EDD4B1652CB9cc5aA6f \
  "getPair(address,address)(address)" \
  0x8f3cf7ad23cd3cadbd9735aff958023239c6a063 \
  0x0d500b1d8e8ef31e21c99d1db9a6444d3adf1270 \
  --rpc-url https://polygon-rpc.com
```

## 交付物
- [ ] SimpleTWAPOracle.sol 合约
- [ ] 部署脚本 Deploy.s.sol (支持 Polygon)
- [ ] 测试文件 SimpleTWAP.t.sol
- [ ] 使用文档 README.md