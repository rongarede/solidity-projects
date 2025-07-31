// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/interfaces/IERC20Metadata.sol";
import "./libraries/MathUtils.sol";
import "./interfaces/IRebaseToken.sol";

contract RebaseToken is IRebaseToken, IERC20Metadata, Ownable {

    // Constants
    uint256 public constant BLOCKS_PER_YEAR = 15_768_000; // Polygon: 365 days * 24 hours * 60 minutes * 60 seconds / 2 seconds per block
    uint256 public constant INITIAL_SUPPLY = 100_000_000 * 10**18; // 100 million tokens
    uint256 public constant INDEX_PRECISION = 1e18;
    uint256 public constant DEFLATION_RATE = 99 * 10**16; // 0.99 in 18 decimal precision

    // ERC20 Metadata
    string private _name;
    string private _symbol;
    uint8 private _decimals;

    // Rebase state
    uint256 public index;
    uint256 public lastRebaseBlock;

    // Shares system
    mapping(address => uint256) private _shares;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalShares;

    // Constructor
    constructor(string memory name_, string memory symbol_, uint8 decimals_) Ownable(msg.sender) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        
        // Initialize rebase system
        index = INDEX_PRECISION;
        lastRebaseBlock = block.number;
        
        // Mint initial supply to deployer
        uint256 shares = _getSharesByAmount(INITIAL_SUPPLY);
        _totalShares = shares;
        _shares[msg.sender] = shares;
        
        emit Transfer(address(0), msg.sender, INITIAL_SUPPLY);
    }

    // ERC20 Metadata functions
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }

    function decimals() public view virtual override returns (uint8) {
        return _decimals;
    }

    // ERC20 total supply (calculated based on current index)
    function totalSupply() public view virtual override returns (uint256) {
        return _getAmountByShares(_totalShares);
    }

    // ERC20 balance (shares converted to amount)
    function balanceOf(address account) public view virtual override returns (uint256) {
        return _getAmountByShares(_shares[account]);
    }

    // Shares specific functions
    function sharesOf(address account) public view virtual override returns (uint256) {
        return _shares[account];
    }

    function totalShares() public view virtual override returns (uint256) {
        return _totalShares;
    }

    // Conversion functions
    function getSharesByAmount(uint256 amount) public view virtual override returns (uint256) {
        return _getSharesByAmount(amount);
    }

    function getAmountByShares(uint256 shares) public view virtual override returns (uint256) {
        return _getAmountByShares(shares);
    }

    // Internal conversion functions
    function _getSharesByAmount(uint256 amount) internal view returns (uint256) {
        return MathUtils.mulDiv(amount, INDEX_PRECISION, index);
    }

    function _getAmountByShares(uint256 shares) internal view returns (uint256) {
        return MathUtils.mulDiv(shares, index, INDEX_PRECISION);
    }

    // ERC20 allowance functions
    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return _allowances[owner][spender];
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    // ERC20 transfer functions
    function transfer(address to, uint256 amount) public virtual override returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public virtual override returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @notice Triggers annual deflation - reduces total supply by 1% per year
     * @dev Only callable by owner, applies compound deflation for elapsed years
     * @dev Formula: newIndex = currentIndex * (0.99)^yearsElapsed
     * @dev Emits Rebase event with yearsElapsed and newIndex
     */
    function rebase() external override onlyOwner {
        uint256 yearsElapsed = _calculateYearsElapsed();
        
        // Only rebase if at least one full year has passed
        if (yearsElapsed == 0) {
            return; // No rebase needed, silently return
        }
        
        // Calculate new index with compound deflation
        uint256 deflationFactor = MathUtils.pow(DEFLATION_RATE, yearsElapsed);
        uint256 newIndex = MathUtils.mulDiv(index, deflationFactor, INDEX_PRECISION);
        
        // Safety check: ensure index doesn't underflow
        require(newIndex <= index, "Math overflow: index increased unexpectedly");
        require(newIndex > 0, "Math underflow: index became zero");
        
        // Update state
        index = newIndex;
        lastRebaseBlock += yearsElapsed * BLOCKS_PER_YEAR;
        
        emit Rebase(yearsElapsed, newIndex);
    }

    /**
     * @notice Provides transparent rebase information for users
     * @return currentIndex The current deflation index (starts at 1e18)
     * @return blocksUntilNextRebase Number of blocks until next eligible rebase
     * @return expectedNextRebaseImpact Expected index after next rebase (1% deflation)
     */
    function getRebaseInfo() external view override returns (
        uint256 currentIndex,
        uint256 blocksUntilNextRebase,
        uint256 expectedNextRebaseImpact
    ) {
        currentIndex = index;
        uint256 yearsElapsed = _calculateYearsElapsed();
        
        if (yearsElapsed > 0) {
            // Rebase is immediately eligible
            blocksUntilNextRebase = 0;
            uint256 deflationFactor = MathUtils.pow(DEFLATION_RATE, yearsElapsed);
            expectedNextRebaseImpact = MathUtils.mulDiv(index, deflationFactor, INDEX_PRECISION);
        } else {
            // Calculate time until next eligible rebase
            uint256 blocksElapsed = block.number - lastRebaseBlock;
            blocksUntilNextRebase = BLOCKS_PER_YEAR - (blocksElapsed % BLOCKS_PER_YEAR);
            expectedNextRebaseImpact = MathUtils.mulDiv(index, DEFLATION_RATE, INDEX_PRECISION);
        }
    }

    /**
     * @dev Internal function to calculate full years elapsed since last rebase
     * @return yearsElapsed Number of complete years that have passed
     */
    function _calculateYearsElapsed() internal view returns (uint256 yearsElapsed) {
        uint256 blocksElapsed = block.number - lastRebaseBlock;
        return blocksElapsed / BLOCKS_PER_YEAR;
    }

    /**
     * @notice Returns comprehensive rebase statistics for UI display
     * @dev This is a convenience function for front-end integrations
     * @return stats Array containing: [currentIndex, nextRebaseBlocks, nextRebaseIndex, totalSupply, totalShares, yearsElapsed]
     */
    function getRebaseStats() external view returns (uint256[6] memory stats) {
        uint256 yearsElapsed = _calculateYearsElapsed();
        
        stats[0] = index; // currentIndex
        stats[1] = yearsElapsed > 0 ? 0 : BLOCKS_PER_YEAR - ((block.number - lastRebaseBlock) % BLOCKS_PER_YEAR); // nextRebaseBlocks
        stats[2] = yearsElapsed > 0 ? 
            MathUtils.mulDiv(index, MathUtils.pow(DEFLATION_RATE, yearsElapsed), INDEX_PRECISION) :
            MathUtils.mulDiv(index, DEFLATION_RATE, INDEX_PRECISION); // nextRebaseIndex
        stats[3] = _getAmountByShares(_totalShares); // totalSupply
        stats[4] = _totalShares; // totalShares
        stats[5] = yearsElapsed; // yearsElapsed
    }

    /**
     * @notice Emergency function to pause rebase operations
     * @dev Only callable by owner, useful for emergency situations
     * @param pause True to pause, false to unpause
     */
    function setRebasePaused(bool pause) external onlyOwner {
        // This is a placeholder for future pause functionality
        // Implementation would add a paused state variable
        emit RebasePaused(pause);
    }

    // Event for pause functionality
    event RebasePaused(bool paused);

    // Internal transfer function
    function _transfer(address from, address to, uint256 amount) internal virtual {
        require(from != address(0), "ERC20: transfer from the zero address");
        require(to != address(0), "ERC20: transfer to the zero address");

        uint256 shares = _getSharesByAmount(amount);
        require(_shares[from] >= shares, "ERC20: transfer amount exceeds balance");

        unchecked {
            _shares[from] -= shares;
            _shares[to] += shares;
        }

        emit Transfer(from, to, amount);
    }

    // Internal approval functions
    function _approve(address owner, address spender, uint256 amount) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal virtual {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "ERC20: insufficient allowance");
            unchecked {
                _approve(owner, spender, currentAllowance - amount);
            }
        }
    }
}