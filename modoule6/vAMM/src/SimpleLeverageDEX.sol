pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// 极简的杠杆 DEX 实现， 完成 TODO 代码部分
contract SimpleLeverageDEX {

    uint public vK;  // 100000 
    uint public vETHAmount;
    uint public vUSDCAmount;

    IERC20 public USDC;  // 自己创建一个币来模拟 USDC

    struct PositionInfo {
        uint256 margin; // 保证金    // 真实的资金， 如 USDC 
        uint256 borrowed; // 借入的资金
        int256 position;    // 虚拟 eth 持仓
    }
    mapping(address => PositionInfo) public positions;

    constructor(uint vEth, uint vUSDC, address _usdc) {
        vETHAmount = vEth;
        vUSDCAmount = vUSDC;
        vK = vEth * vUSDC;
        USDC = IERC20(_usdc);
    }


    // 开启杠杆头寸
    function openPosition(uint256 _margin, uint level, bool long) external {
        require(positions[msg.sender].position == 0, "Position already open");

        PositionInfo storage pos = positions[msg.sender] ;

        USDC.transferFrom(msg.sender, address(this), _margin); // 用户提供保证金
        uint amount = _margin * level;
        uint256 borrowAmount = amount - _margin;

        pos.margin = _margin;
        pos.borrowed = borrowAmount;

        if (long) {
            // Calculate how much virtual ETH can be bought with the total amount
            uint256 newVUSDCAmount = vUSDCAmount + amount;
            uint256 newVETHAmount = vK / newVUSDCAmount;
            require(vETHAmount > newVETHAmount, "Invalid calculation");
            uint256 vETHBought = vETHAmount - newVETHAmount;
            pos.position = int256(vETHBought);
            
            // Update vAMM state
            vUSDCAmount = newVUSDCAmount;
            vETHAmount = newVETHAmount;
        } else {
            // Calculate how much virtual ETH to sell to get the total amount
            require(amount < vUSDCAmount, "Trade too large");
            uint256 newVUSDCAmount = vUSDCAmount - amount;
            uint256 newVETHAmount = vK / newVUSDCAmount;
            require(newVETHAmount > vETHAmount, "Invalid calculation");
            uint256 vETHSold = newVETHAmount - vETHAmount;
            pos.position = -int256(vETHSold);
            
            // Update vAMM state
            vUSDCAmount = newVUSDCAmount;
            vETHAmount = newVETHAmount;
        }
        
    }

    // 关闭头寸并结算, 不考虑协议亏损
    function closePosition() external {
        PositionInfo memory position = positions[msg.sender];
        require(position.position != 0, "No open position");
        
        int256 pnl = calculatePnL(msg.sender);
        
        if (position.position > 0) {
            // Long position: sell virtual ETH back to vAMM
            uint256 vETHToSell = uint256(position.position);
            uint256 newVETHAmount = vETHAmount + vETHToSell;
            uint256 newVUSDCAmount = vK / newVETHAmount;
            require(vUSDCAmount > newVUSDCAmount, "Invalid close calculation");
            
            // Update vAMM state
            vETHAmount = newVETHAmount;
            vUSDCAmount = newVUSDCAmount;
            
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
        } else {
            // Short position: buy back virtual ETH from vAMM
            uint256 vETHToBuy = uint256(-position.position);
            require(vETHAmount > 0, "No liquidity");
            uint256 currentPrice = vUSDCAmount * 1e18 / vETHAmount;
            uint256 costToBuyBack = vETHToBuy * currentPrice / 1e18;
            
            uint256 newVUSDCAmount = vUSDCAmount + costToBuyBack;
            uint256 newVETHAmount = vK / newVUSDCAmount;
            require(vETHAmount > newVETHAmount, "Invalid close calculation");
            
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

    // 清算头寸， 清算的逻辑和关闭头寸类似，不过利润由清算用户获取
    // 注意： 清算人不能是自己，同时设置一个清算条件，例如亏损大于保证金的 80%
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
            require(vETHAmount > 0, "No liquidity");
            uint256 currentPrice = vUSDCAmount * 1e18 / vETHAmount;
            uint256 costToBuyBack = vETHToBuy * currentPrice / 1e18;
            
            uint256 newVUSDCAmount = vUSDCAmount + costToBuyBack;
            uint256 newVETHAmount = vK / newVUSDCAmount;
            require(vETHAmount > newVETHAmount, "Invalid liquidation calculation");
            
            vUSDCAmount = newVUSDCAmount;
            vETHAmount = newVETHAmount;
        }
        
        // Calculate liquidator reward (5% of margin)
        uint256 liquidatorReward = (position.margin * 5) / 100;
        
        // Transfer reward to liquidator
        USDC.transfer(msg.sender, liquidatorReward);
        
        delete positions[_user];
        
    }

    // 计算盈亏： 对比当前的仓位和借的 vUSDC
    function calculatePnL(address user) public view returns (int256) {
        PositionInfo memory position = positions[user];
        require(position.position != 0, "No open position");
        require(vETHAmount > 0, "No liquidity");
        
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
}