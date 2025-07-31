// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

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