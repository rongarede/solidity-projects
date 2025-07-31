// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./ISimpleTWAP.sol";

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function price0CumulativeLast() external view returns (uint256);
    function getReserves() external view returns (uint112 reserve0, uint112 reserve1, uint32 blockTimestampLast);
}

struct Observation {
    uint256 timestamp;           // 观察时间戳
    uint256 price0Cumulative;    // DAI 累积价格
}

contract SimpleTWAPOracle is ISimpleTWAP {
    // Uniswap V2 Factory on Polygon
    address public constant FACTORY = 0x800b052609c355cA8103E06F022aA30647eAd60a;
    
    // Token addresses on Polygon
    address public constant DAI = 0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063;
    address public constant WMATIC = 0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270;
    
    // 30 秒时间窗口（便于测试）
    uint256 public constant TIME_WINDOW = 30;
    
    // 两个观察点用于计算 TWAP
    Observation public firstObservation;   // 较早的观察点
    Observation public secondObservation;  // 较新的观察点
    
    // 合约所有者
    address public owner;
    
    // 当前缓存的 TWAP 价格
    uint256 public cachedPrice;
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only owner can call this function");
        _;
    }
    
    constructor() {
        owner = msg.sender;
    }
    
    function _getPairAddress() internal view returns (address) {
        return IUniswapV2Factory(FACTORY).getPair(DAI, WMATIC);
    }
    
    function _getCurrentData() internal view returns (uint256, uint32) {
        address pairAddress = _getPairAddress();
        require(pairAddress != address(0), "Pair does not exist");
        
        IUniswapV2Pair pair = IUniswapV2Pair(pairAddress);
        
        uint256 price0Cumulative = pair.price0CumulativeLast();
        (, , uint32 blockTimestampLast) = pair.getReserves();
        
        // 使用当前区块时间戳，而不是池子的最后更新时间戳
        // 这样可以确保每次调用都有不同的时间戳
        return (price0Cumulative, uint32(block.timestamp));
    }
    
    function update() external override {
        (uint256 price0Cumulative, uint32 blockTimestamp) = _getCurrentData();
        
        // 如果是第一次更新，只初始化第一个观察点
        if (firstObservation.timestamp == 0) {
            firstObservation = Observation(blockTimestamp, price0Cumulative);
            return;
        }
        
        // 移动时间窗口：如果当前时间超过时间窗口且第二个观察点已初始化，移动第一个观察点
        if (secondObservation.timestamp != 0 && blockTimestamp - firstObservation.timestamp >= TIME_WINDOW) {
            firstObservation = secondObservation;
        }
        
        // 更新第二个观察点
        secondObservation = Observation(blockTimestamp, price0Cumulative);
        
        // 计算并缓存新的 TWAP 价格
        if (canComputeTWAP()) {
            cachedPrice = _computeTWAP();
            emit PriceUpdated(cachedPrice, blockTimestamp);
        }
    }
    
    function _computeTWAP() internal view returns (uint256) {
        uint256 timeElapsed = secondObservation.timestamp - firstObservation.timestamp;
        uint256 priceChange = secondObservation.price0Cumulative - firstObservation.price0Cumulative;
        
        return priceChange / timeElapsed;
    }
    
    function getPrice() external view override returns (uint256) {
        require(canComputeTWAP(), "Insufficient data for TWAP calculation");
        return cachedPrice;
    }
    
    function lastUpdateTime() external view override returns (uint256) {
        return secondObservation.timestamp;
    }
    
    function canComputeTWAP() public view override returns (bool) {
        return firstObservation.timestamp != 0 && 
               secondObservation.timestamp > firstObservation.timestamp;
    }
}