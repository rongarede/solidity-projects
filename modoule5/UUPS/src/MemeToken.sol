// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/contracts/proxy/utils/Initializable.sol";
import "lib/openzeppelin-contracts/contracts/proxy/utils/UUPSUpgradeable.sol";
import "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
import "lib/openzeppelin-contracts/contracts/interfaces/IERC20.sol";

/**
 * @title MemeToken
 * @dev 可升级的 Meme 代币合约，使用 UUPS 代理模式
 */
contract MemeToken is Initializable, UUPSUpgradeable, Ownable, IERC20 {
    /// @dev 代币名称
    string private _name;
    
    /// @dev 代币符号
    string private _symbol;
    
    /// @dev 小数位数
    uint8 private _decimals;
    
    /// @dev 余额映射
    mapping(address => uint256) private _balances;
    
    /// @dev 授权映射
    mapping(address => mapping(address => uint256)) private _allowances;
    
    /// @dev 最大总供应量
    uint256 public maxTotalSupply;
    
    /// @dev 每次最大铸造数量
    uint256 public perMint;
    
    /// @dev 代币价格（以 wei 为单位）
    uint256 public price;
    
    /// @dev 已铸造总量
    uint256 public totalMinted;
    
    /// @dev 代币发行者
    address public issuer;

    /// @dev 事件定义
    event TokenMinted(address indexed to, uint256 amount);
    event PriceUpdated(uint256 oldPrice, uint256 newPrice);
    event PerMintUpdated(uint256 oldPerMint, uint256 newPerMint);

    /// @custom:oz-upgrades-unsafe-allow constructor
    constructor() Ownable(msg.sender) {
        _disableInitializers();
    }

    /**
     * @dev 初始化函数（替代构造函数）
     * @param _tokenSymbol 代币符号
     * @param _maxTotalSupply 最大总供应量
     * @param _perMint 每次最大铸造数量
     * @param _price 代币价格
     * @param _issuer 代币发行者
     */
    function initialize(
        string memory _tokenSymbol,
        uint256 _maxTotalSupply,
        uint256 _perMint,
        uint256 _price,
        address _issuer
    ) public initializer {
        require(bytes(_tokenSymbol).length > 0, "MemeToken: symbol cannot be empty");
        require(_maxTotalSupply > 0, "MemeToken: maxTotalSupply must be greater than 0");
        require(_perMint > 0, "MemeToken: perMint must be greater than 0");
        require(_price > 0, "MemeToken: price must be greater than 0");
        require(_issuer != address(0), "MemeToken: issuer cannot be zero address");
        require(_perMint <= _maxTotalSupply, "MemeToken: perMint cannot exceed maxTotalSupply");

        // 设置代币信息
        _name = string(abi.encodePacked("Meme", _tokenSymbol));
        _symbol = _tokenSymbol;
        _decimals = 18;
        
        // 初始化 Ownable - 工厂合约是 owner，可以调用 mint
        _transferOwnership(msg.sender);

        maxTotalSupply = _maxTotalSupply;
        perMint = _perMint;
        price = _price;
        issuer = _issuer;
        totalMinted = 0;
    }

    /**
     * @dev 返回代币名称
     */
    function name() public view returns (string memory) {
        return _name;
    }

    /**
     * @dev 返回代币符号
     */
    function symbol() public view returns (string memory) {
        return _symbol;
    }

    /**
     * @dev 返回小数位数
     */
    function decimals() public view returns (uint8) {
        return _decimals;
    }

    /**
     * @dev 返回总供应量
     */
    function totalSupply() public view override returns (uint256) {
        return totalMinted;
    }

    /**
     * @dev 返回账户余额
     */
    function balanceOf(address account) public view override returns (uint256) {
        return _balances[account];
    }

    /**
     * @dev 转账
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
        _transfer(owner, to, amount);
        return true;
    }

    /**
     * @dev 返回授权额度
     */
    function allowance(address owner, address spender) public view override returns (uint256) {
        return _allowances[owner][spender];
    }

    /**
     * @dev 授权
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        address owner = msg.sender;
        _approve(owner, spender, amount);
        return true;
    }

    /**
     * @dev 授权转账
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        address spender = msg.sender;
        _spendAllowance(from, spender, amount);
        _transfer(from, to, amount);
        return true;
    }

    /**
     * @dev 铸造代币（仅工厂合约可调用）
     * @param to 接收者地址
     * @param amount 铸造数量
     */
    function mint(address to, uint256 amount) external onlyOwner {
        require(to != address(0), "MemeToken: mint to zero address");
        require(amount > 0, "MemeToken: amount must be greater than 0");
        require(amount <= perMint, "MemeToken: amount exceeds perMint limit");
        require(totalMinted + amount <= maxTotalSupply, "MemeToken: would exceed max supply");
        require(!isMaxSupplyReached(), "MemeToken: max supply already reached");

        totalMinted += amount;
        _balances[to] += amount;

        emit Transfer(address(0), to, amount);
        emit TokenMinted(to, amount);
    }

    /**
     * @dev 内部转账函数
     */
    function _transfer(address from, address to, uint256 amount) internal {
        require(from != address(0), "MemeToken: transfer from zero address");
        require(to != address(0), "MemeToken: transfer to zero address");

        uint256 fromBalance = _balances[from];
        require(fromBalance >= amount, "MemeToken: transfer amount exceeds balance");
        
        _balances[from] = fromBalance - amount;
        _balances[to] += amount;

        emit Transfer(from, to, amount);
    }

    /**
     * @dev 内部授权函数
     */
    function _approve(address owner, address spender, uint256 amount) internal {
        require(owner != address(0), "MemeToken: approve from zero address");
        require(spender != address(0), "MemeToken: approve to zero address");

        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    /**
     * @dev 内部授权消费函数
     */
    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        if (currentAllowance != type(uint256).max) {
            require(currentAllowance >= amount, "MemeToken: insufficient allowance");
            _approve(owner, spender, currentAllowance - amount);
        }
    }

    /**
     * @dev 更新代币价格（仅发行者可调用）
     * @param newPrice 新价格
     */
    function updatePrice(uint256 newPrice) external {
        require(msg.sender == issuer, "MemeToken: only issuer can update price");
        require(newPrice > 0, "MemeToken: price must be greater than 0");

        uint256 oldPrice = price;
        price = newPrice;

        emit PriceUpdated(oldPrice, newPrice);
    }

    /**
     * @dev 更新每次最大铸造数量（仅发行者可调用）
     * @param newPerMint 新的每次最大铸造数量
     */
    function updatePerMint(uint256 newPerMint) external {
        require(msg.sender == issuer, "MemeToken: only issuer can update perMint");
        require(newPerMint > 0, "MemeToken: perMint must be greater than 0");
        require(newPerMint <= maxTotalSupply, "MemeToken: perMint cannot exceed maxTotalSupply");

        uint256 oldPerMint = perMint;
        perMint = newPerMint;

        emit PerMintUpdated(oldPerMint, newPerMint);
    }

    /**
     * @dev 检查是否达到最大供应量
     */
    function isMaxSupplyReached() public view returns (bool) {
        return totalMinted >= maxTotalSupply;
    }

    /**
     * @dev 获取剩余可铸造数量
     */
    function getRemainingSupply() external view returns (uint256) {
        return maxTotalSupply - totalMinted;
    }

    /**
     * @dev 授权升级（仅发行者可调用）
     */
    function _authorizeUpgrade(address newImplementation) internal override {
        require(msg.sender == issuer, "MemeToken: only issuer can upgrade");
    }

    /**
     * @dev 获取代币详细信息
     */
    function getTokenDetails() external view returns (
        string memory tokenName,
        string memory tokenSymbol,
        uint256 currentTotalSupply,
        uint256 maxSupply,
        uint256 mintLimit,
        uint256 tokenPrice,
        address tokenIssuer,
        bool maxSupplyReached
    ) {
        return (
            name(),
            symbol(),
            totalMinted,
            maxTotalSupply,
            perMint,
            price,
            issuer,
            isMaxSupplyReached()
        );
    }
}