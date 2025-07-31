// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * @title SimpleLeverageDEXFixed
 * @dev Fixed version of SimpleLeverageDEX with proper vAMM mechanics and safety checks
 */
contract SimpleLeverageDEXFixed {
    uint public vK;
    uint public vETHAmount;
    uint public vUSDCAmount;

    IERC20 public USDC;

    struct PositionInfo {
        uint256 margin;     // User's margin in USDC
        uint256 borrowed;   // Borrowed amount in USDC
        int256 position;    // Virtual ETH position (positive for long, negative for short)
        uint256 entryPrice; // Entry price when position was opened
    }
    mapping(address => PositionInfo) public positions;

    // Constants for safety
    uint256 private constant MIN_LIQUIDITY = 100; // Minimum liquidity to prevent drainage
    uint256 private constant LIQUIDATION_THRESHOLD = 80; // 80% loss threshold
    uint256 private constant LIQUIDATION_REWARD = 5; // 5% reward for liquidators

    event PositionOpened(address indexed user, uint256 margin, uint256 leverage, bool isLong, int256 position);
    event PositionClosed(address indexed user, int256 pnl);
    event PositionLiquidated(address indexed user, address indexed liquidator, uint256 reward);

    constructor(uint vEth, uint vUSDC, address _usdc) {
        require(vEth > MIN_LIQUIDITY && vUSDC > MIN_LIQUIDITY, "Insufficient initial liquidity");
        vETHAmount = vEth;
        vUSDCAmount = vUSDC;
        vK = vEth * vUSDC;
        USDC = IERC20(_usdc);
    }

    function openPosition(uint256 _margin, uint level, bool long) external {
        require(positions[msg.sender].position == 0, "Position already open");
        require(_margin > 0, "Margin must be positive");
        require(level >= 1 && level <= 20, "Leverage must be between 1 and 20");

        PositionInfo storage pos = positions[msg.sender];
        
        USDC.transferFrom(msg.sender, address(this), _margin);
        
        uint256 amount = _margin * level;
        uint256 borrowAmount = amount - _margin;
        uint256 entryPrice = getCurrentPrice();

        pos.margin = _margin;
        pos.borrowed = borrowAmount;
        pos.entryPrice = entryPrice;

        if (long) {
            // Long: buy virtual ETH
            uint256 newVUSDCAmount = vUSDCAmount + amount;
            uint256 newVETHAmount = vK / newVUSDCAmount;
            
            require(newVETHAmount >= MIN_LIQUIDITY, "Insufficient liquidity for trade");
            require(vETHAmount > newVETHAmount, "Invalid trade calculation");
            
            uint256 vETHBought = vETHAmount - newVETHAmount;
            pos.position = int256(vETHBought);
            
            vUSDCAmount = newVUSDCAmount;
            vETHAmount = newVETHAmount;
        } else {
            // Short: sell virtual ETH
            require(amount < vUSDCAmount, "Trade too large for pool");
            
            uint256 newVUSDCAmount = vUSDCAmount - amount;
            require(newVUSDCAmount >= MIN_LIQUIDITY, "Insufficient liquidity for trade");
            
            uint256 newVETHAmount = vK / newVUSDCAmount;
            require(newVETHAmount > vETHAmount, "Invalid trade calculation");
            
            uint256 vETHSold = newVETHAmount - vETHAmount;
            pos.position = -int256(vETHSold);
            
            vUSDCAmount = newVUSDCAmount;
            vETHAmount = newVETHAmount;
        }

        emit PositionOpened(msg.sender, _margin, level, long, pos.position);
    }

    function closePosition() external {
        PositionInfo memory position = positions[msg.sender];
        require(position.position != 0, "No open position");
        
        int256 pnl = calculatePnL(msg.sender);
        
        if (position.position > 0) {
            // Close long position: sell virtual ETH back
            uint256 vETHToSell = uint256(position.position);
            uint256 newVETHAmount = vETHAmount + vETHToSell;
            uint256 newVUSDCAmount = vK / newVETHAmount;
            
            require(newVUSDCAmount >= MIN_LIQUIDITY, "Insufficient pool liquidity");
            require(vUSDCAmount > newVUSDCAmount, "Invalid close calculation");
            
            vETHAmount = newVETHAmount;
            vUSDCAmount = newVUSDCAmount;
        } else {
            // Close short position: buy back virtual ETH
            uint256 vETHToBuy = uint256(-position.position);
            uint256 newVETHAmount = vETHAmount - vETHToBuy;
            require(newVETHAmount >= MIN_LIQUIDITY, "Insufficient pool liquidity");
            
            uint256 newVUSDCAmount = vK / newVETHAmount;
            require(newVUSDCAmount > vUSDCAmount, "Invalid close calculation");
            
            vETHAmount = newVETHAmount;
            vUSDCAmount = newVUSDCAmount;
        }
        
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
        
        delete positions[msg.sender];
        emit PositionClosed(msg.sender, pnl);
    }

    function liquidatePosition(address _user) external {
        require(msg.sender != _user, "Cannot liquidate own position");
        
        PositionInfo memory position = positions[_user];
        require(position.position != 0, "No open position");
        
        int256 pnl = calculatePnL(_user);
        require(pnl < 0, "Position not in loss");
        
        uint256 loss = uint256(-pnl);
        uint256 liquidationThreshold = (position.margin * LIQUIDATION_THRESHOLD) / 100;
        require(loss > liquidationThreshold, "Position not liquidatable");
        
        // Close the position (similar logic to closePosition)
        if (position.position > 0) {
            uint256 vETHToSell = uint256(position.position);
            vETHAmount = vETHAmount + vETHToSell;
            vUSDCAmount = vK / vETHAmount;
        } else {
            uint256 vETHToBuy = uint256(-position.position);
            vETHAmount = vETHAmount - vETHToBuy;
            vUSDCAmount = vK / vETHAmount;
        }
        
        // Calculate and transfer liquidator reward
        uint256 liquidatorReward = (position.margin * LIQUIDATION_REWARD) / 100;
        USDC.transfer(msg.sender, liquidatorReward);
        
        delete positions[_user];
        emit PositionLiquidated(_user, msg.sender, liquidatorReward);
    }

    function calculatePnL(address user) public view returns (int256) {
        PositionInfo memory position = positions[user];
        require(position.position != 0, "No open position");
        
        uint256 currentPrice = getCurrentPrice();
        
        if (position.position > 0) {
            // Long position P&L
            uint256 positionValue = uint256(position.position) * currentPrice / 1e18;
            return int256(positionValue) - int256(position.borrowed);
        } else {
            // Short position P&L
            uint256 vETHAmount_abs = uint256(-position.position);
            uint256 currentCost = vETHAmount_abs * currentPrice / 1e18;
            return int256(position.borrowed) - int256(currentCost);
        }
    }

    function getCurrentPrice() public view returns (uint256) {
        require(vETHAmount > 0, "No liquidity");
        return vUSDCAmount * 1e18 / vETHAmount;
    }

    // View functions for testing
    function getPoolState() external view returns (uint256 ethAmount, uint256 usdcAmount, uint256 k, uint256 price) {
        return (vETHAmount, vUSDCAmount, vK, getCurrentPrice());
    }
}