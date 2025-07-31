# SimpleLeverageDEX TODO Implementation Plan

## Overview
This plan focuses on completing the 4 TODO sections in the SimpleLeverageDEX contract to implement a functional leverage trading system using virtual AMM (vAMM) mechanics.

## Implementation Steps

### 1. Complete openPosition TODO - Position Calculation Logic

**Location**: `openPosition()` function - Calculate `pos.position` for long/short

**Implementation Details**:
- **Long Position Logic**:
  ```solidity
  // Calculate how much virtual ETH can be bought with the total amount
  uint256 newVUSDCAmount = vUSDCAmount + amount;
  uint256 newVETHAmount = vK / newVUSDCAmount;
  uint256 vETHBought = vETHAmount - newVETHAmount;
  pos.position = int256(vETHBought);
  
  // Update vAMM state
  vUSDCAmount = newVUSDCAmount;
  vETHAmount = newVETHAmount;
  ```

- **Short Position Logic**:
  ```solidity
  // Calculate how much virtual ETH to sell to get the total amount
  uint256 newVUSDCAmount = vUSDCAmount - amount;
  uint256 newVETHAmount = vK / newVUSDCAmount;
  uint256 vETHSold = newVETHAmount - vETHAmount;
  pos.position = -int256(vETHSold);
  
  // Update vAMM state
  vUSDCAmount = newVUSDCAmount;
  vETHAmount = newVETHAmount;
  ```

**Key Formula**: Use constant product formula `x * y = k` where `vETHAmount * vUSDCAmount = vK`

### 2. Complete calculatePnL TODO - Profit/Loss Calculation

**Location**: `calculatePnL()` function

**Implementation Logic**:
```solidity
function calculatePnL(address user) public view returns (int256) {
    PositionInfo memory position = positions[user];
    require(position.position != 0, "No open position");
    
    if (position.position > 0) {
        // Long position: calculate current value of virtual ETH held
        uint256 currentPrice = vUSDCAmount * 1e18 / vETHAmount; // Price in USDC per ETH
        uint256 currentValue = uint256(position.position) * currentPrice / 1e18;
        return int256(currentValue) - int256(position.borrowed);
    } else {
        // Short position: calculate profit from price decrease
        uint256 currentPrice = vUSDCAmount * 1e18 / vETHAmount;
        uint256 vETHAmount_abs = uint256(-position.position);
        uint256 currentCost = vETHAmount_abs * currentPrice / 1e18;
        return int256(position.borrowed) - int256(currentCost);
    }
}
```

**Key Concepts**:
- Long PnL = Current Position Value - Borrowed Amount
- Short PnL = Borrowed Amount - Current Cost to Buy Back
- Use current vAMM price: `vUSDCAmount / vETHAmount`

### 3. Complete closePosition TODO - Position Settlement

**Location**: `closePosition()` function

**Implementation Steps**:
```solidity
function closePosition() external {
    PositionInfo memory position = positions[msg.sender];
    require(position.position != 0, "No open position");
    
    int256 pnl = calculatePnL(msg.sender);
    
    if (position.position > 0) {
        // Long position: sell virtual ETH back to vAMM
        uint256 vETHToSell = uint256(position.position);
        uint256 newVETHAmount = vETHAmount + vETHToSell;
        uint256 newVUSDCAmount = vK / newVETHAmount;
        uint256 usdcReceived = vUSDCAmount - newVUSDCAmount;
        
        // Update vAMM state
        vETHAmount = newVETHAmount;
        vUSDCAmount = newVUSDCAmount;
        
        // Settle with user
        uint256 totalReturn = position.margin + uint256(pnl);
        USDC.transfer(msg.sender, totalReturn);
    } else {
        // Short position: buy back virtual ETH from vAMM
        uint256 vETHToBuy = uint256(-position.position);
        uint256 currentPrice = vUSDCAmount * 1e18 / vETHAmount;
        uint256 costToBuyBack = vETHToBuy * currentPrice / 1e18;
        
        uint256 newVUSDCAmount = vUSDCAmount + costToBuyBack;
        uint256 newVETHAmount = vK / newVUSDCAmount;
        
        // Update vAMM state
        vUSDCAmount = newVUSDCAmount;
        vETHAmount = newVETHAmount;
        
        // Settle with user
        if (pnl >= 0) {
            uint256 totalReturn = position.margin + uint256(pnl);
            USDC.transfer(msg.sender, totalReturn);
        } else {
            uint256 loss = uint256(-pnl);
            if (loss < position.margin) {
                USDC.transfer(msg.sender, position.margin - loss);
            }
            // If loss >= margin, user gets nothing
        }
    }
    
    delete positions[msg.sender];
}
```

### 4. Complete liquidatePosition TODO - Liquidation Logic

**Location**: `liquidatePosition()` function

**Implementation Requirements**:
```solidity
function liquidatePosition(address _user) external {
    require(msg.sender != _user, "Cannot liquidate own position");
    
    PositionInfo memory position = positions[_user];
    require(position.position != 0, "No open position");
    
    int256 pnl = calculatePnL(_user);
    
    // Liquidation condition: loss > 80% of margin
    require(pnl < 0 && uint256(-pnl) > (position.margin * 80) / 100, "Position not liquidatable");
    
    // Close the position (similar to closePosition but rewards go to liquidator)
    if (position.position > 0) {
        // Long position liquidation
        uint256 vETHToSell = uint256(position.position);
        uint256 newVETHAmount = vETHAmount + vETHToSell;
        uint256 newVUSDCAmount = vK / newVETHAmount;
        
        vETHAmount = newVETHAmount;
        vUSDCAmount = newVUSDCAmount;
    } else {
        // Short position liquidation
        uint256 vETHToBuy = uint256(-position.position);
        uint256 currentPrice = vUSDCAmount * 1e18 / vETHAmount;
        uint256 costToBuyBack = vETHToBuy * currentPrice / 1e18;
        
        uint256 newVUSDCAmount = vUSDCAmount + costToBuyBack;
        uint256 newVETHAmount = vK / newVUSDCAmount;
        
        vUSDCAmount = newVUSDCAmount;
        vETHAmount = newVETHAmount;
    }
    
    // Calculate liquidator reward (e.g., 5% of margin)
    uint256 liquidatorReward = (position.margin * 5) / 100;
    
    // Transfer reward to liquidator
    USDC.transfer(msg.sender, liquidatorReward);
    
    // Remaining margin (if any) goes to protocol or is burned
    
    delete positions[_user];
}
```

**Key Features**:
- Liquidation threshold: Loss > 80% of margin
- Liquidator receives 5% of original margin as reward
- Self-liquidation protection
- Position closure updates vAMM state

## Implementation Order

1. **Start with calculatePnL** - This is needed by other functions
2. **Implement openPosition logic** - Core position opening mechanism
3. **Complete closePosition** - Normal position closure
4. **Finish liquidatePosition** - Emergency position closure

## Testing Considerations

After implementation, test:
- Long/short position opening with different leverage levels
- PnL calculation accuracy under various price movements
- Position closure with profits and losses
- Liquidation trigger conditions and rewards
- vAMM state consistency after operations

## Key Mathematical Formulas

- **Constant Product**: `vETHAmount * vUSDCAmount = vK`
- **Current Price**: `price = vUSDCAmount / vETHAmount`
- **Long PnL**: `currentPositionValue - borrowedAmount`
- **Short PnL**: `borrowedAmount - currentCostToBuyBack`
- **Liquidation Threshold**: `loss > margin * 0.8`