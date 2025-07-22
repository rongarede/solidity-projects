// SPDX-License-Identifier: MIT
pragma solidity ^0.8.27;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IMemeToken.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/IUniswapV2Factory.sol";
import "./interfaces/IUniswapV2Pair.sol";

contract MemeFactory is ReentrancyGuard, Ownable {
    address public immutable TEMPLATE;
    IUniswapV2Router02 public immutable ROUTER;
    address public immutable WETH;
    address public platformWallet;

    uint256 public constant PLATFORM_FEE_RATE = 500; // 5%
    uint256 public constant LIQUIDITY_THRESHOLD = 0.1 ether;

    struct TokenData {
        address tokenAddress;
        address creator;
        uint256 totalSupply;
        uint256 pricePerToken;
        uint256 soldAmount;
        uint256 raisedETH;
        bool liquidityAdded;
        string name;
        string symbol;
    }

    mapping(address => TokenData) public tokens;
    mapping(string => address) public symbolToToken;
    address[] public allTokens;

    event MemeTokenDeployed(
        address indexed tokenAddress,
        address indexed creator,
        string name,
        string symbol,
        uint256 totalSupply,
        uint256 pricePerToken
    );

    event MemeTokenMinted(
        address indexed tokenAddress,
        address indexed buyer,
        uint256 amount,
        uint256 cost,
        uint256 platformFee
    );

    event LiquidityAdded(
        address indexed tokenAddress,
        uint256 tokenAmount,
        uint256 ethAmount,
        address pair
    );

    event MemeTokenPurchased(
        address indexed tokenAddress,
        address indexed buyer,
        uint256 amountIn,
        uint256 amountOut
    );

    constructor(
        address _template,
        address _router,
        address _weth,
        address _platformWallet
    ) Ownable(msg.sender) {
        require(_template != address(0), "Invalid template address");
        require(_router != address(0), "Invalid router address");
        require(_weth != address(0), "Invalid WETH address");
        require(_platformWallet != address(0), "Invalid platform wallet");

        TEMPLATE = _template;
        ROUTER = IUniswapV2Router02(_router);
        WETH = _weth;
        platformWallet = _platformWallet;
    }

    function deployMeme(
        string memory _name,
        string memory _symbol,
        uint256 _totalSupply,
        uint256 _pricePerToken
    ) external returns (address) {
        require(bytes(_name).length > 0 && bytes(_name).length <= 50, "Invalid name length");
        require(bytes(_symbol).length > 0 && bytes(_symbol).length <= 10, "Invalid symbol length");
        require(_totalSupply > 0 && _totalSupply <= 1e12 * 1e18, "Invalid total supply");
        require(_pricePerToken > 0, "Invalid price per token");
        require(symbolToToken[_symbol] == address(0), "Symbol already exists");

        bytes32 salt = keccak256(abi.encodePacked(_symbol, msg.sender, block.timestamp));
        address clone = Clones.cloneDeterministic(TEMPLATE, salt);

        IMemeToken(clone).initialize(
            _name,
            _symbol,
            _totalSupply,
            _pricePerToken,
            msg.sender,
            address(this)
        );

        TokenData memory tokenData = TokenData({
            tokenAddress: clone,
            creator: msg.sender,
            totalSupply: _totalSupply,
            pricePerToken: _pricePerToken,
            soldAmount: 0,
            raisedETH: 0,
            liquidityAdded: false,
            name: _name,
            symbol: _symbol
        });

        tokens[clone] = tokenData;
        symbolToToken[_symbol] = clone;
        allTokens.push(clone);

        emit MemeTokenDeployed(
            clone,
            msg.sender,
            _name,
            _symbol,
            _totalSupply,
            _pricePerToken
        );

        return clone;
    }

    function mintMeme(address _tokenAddress, uint256 _amount) 
        external 
        payable 
        nonReentrant 
    {
        require(_tokenAddress != address(0), "Invalid token address");
        require(_amount > 0, "Amount must be greater than zero");
        
        TokenData storage tokenData = tokens[_tokenAddress];
        require(tokenData.tokenAddress != address(0), "Token not found");
        require(!tokenData.liquidityAdded, "Liquidity already added");

        uint256 cost = _amount * tokenData.pricePerToken / 1e18;
        require(msg.value >= cost, "Insufficient payment");
        require(
            tokenData.soldAmount + _amount <= tokenData.totalSupply,
            "Cannot exceed total supply"
        );

        uint256 platformFee = (cost * PLATFORM_FEE_RATE) / 10000;
        uint256 remainingETH = cost - platformFee;

        tokenData.soldAmount += _amount;
        tokenData.raisedETH += remainingETH;

        IMemeToken(_tokenAddress).mint(msg.sender, _amount);

        if (platformFee > 0) {
            payable(platformWallet).transfer(platformFee);
        }

        if (tokenData.raisedETH >= LIQUIDITY_THRESHOLD && !tokenData.liquidityAdded) {
            _addInitialLiquidity(_tokenAddress);
        }

        if (msg.value > cost) {
            payable(msg.sender).transfer(msg.value - cost);
        }

        emit MemeTokenMinted(_tokenAddress, msg.sender, _amount, cost, platformFee);
    }

    function buyMeme(address _tokenAddress, uint256 _minAmountOut) 
        external 
        payable 
        nonReentrant 
    {
        require(_tokenAddress != address(0), "Invalid token address");
        require(msg.value > 0, "Must send ETH");
        
        TokenData storage tokenData = tokens[_tokenAddress];
        require(tokenData.tokenAddress != address(0), "Token not found");
        require(tokenData.liquidityAdded, "Liquidity not yet added");

        address pair = IUniswapV2Factory(ROUTER.factory()).getPair(_tokenAddress, WETH);
        require(pair != address(0), "Pair does not exist");

        uint256 initialPrice = tokenData.pricePerToken;
        uint256 currentPrice = _getCurrentPrice(_tokenAddress);
        require(currentPrice <= initialPrice, "Price is higher than initial price");

        address[] memory path = new address[](2);
        path[0] = WETH;
        path[1] = _tokenAddress;

        uint256[] memory amounts = ROUTER.swapExactETHForTokens{value: msg.value}(
            _minAmountOut,
            path,
            msg.sender,
            block.timestamp + 300
        );

        emit MemeTokenPurchased(_tokenAddress, msg.sender, amounts[0], amounts[1]);
    }

    function _addInitialLiquidity(address _tokenAddress) private {
        TokenData storage tokenData = tokens[_tokenAddress];
        require(!tokenData.liquidityAdded, "Liquidity already added");

        uint256 tokenAmount = tokenData.raisedETH * 1e18 / tokenData.pricePerToken;
        uint256 ethAmount = tokenData.raisedETH;

        IMemeToken(_tokenAddress).mint(address(this), tokenAmount);
        
        IMemeToken(_tokenAddress).approve(address(ROUTER), tokenAmount);

        // 这里调用了Uniswap V2的添加流动性函数
        (uint256 amountToken, uint256 amountETH, ) = 
            ROUTER.addLiquidityETH{value: ethAmount}(
                _tokenAddress,
                tokenAmount,
                0,
                0,
                address(this),
                block.timestamp + 300
            );

        tokenData.liquidityAdded = true;
        address pair = IUniswapV2Factory(ROUTER.factory()).getPair(_tokenAddress, WETH);
        
        emit LiquidityAdded(_tokenAddress, amountToken, amountETH, pair);
    }

    function _getCurrentPrice(address _tokenAddress) private view returns (uint256) {
        address pair = IUniswapV2Factory(ROUTER.factory()).getPair(_tokenAddress, WETH);
        if (pair == address(0)) return 0;

        (uint112 reserve0, uint112 reserve1, ) = IUniswapV2Pair(pair).getReserves();
        
        address token0 = IUniswapV2Pair(pair).token0();
        
        if (token0 == _tokenAddress) {
            return reserve0 > 0 ? (uint256(reserve1) * 1e18) / uint256(reserve0) : 0;
        } else {
            return reserve1 > 0 ? (uint256(reserve0) * 1e18) / uint256(reserve1) : 0;
        }
    }

    function getTokenData(address _tokenAddress) external view returns (TokenData memory) {
        return tokens[_tokenAddress];
    }

    function getAllTokens() external view returns (address[] memory) {
        return allTokens;
    }

    function getTokensCount() external view returns (uint256) {
        return allTokens.length;
    }

    function setPlatformWallet(address _newPlatformWallet) external onlyOwner {
        require(_newPlatformWallet != address(0), "Invalid platform wallet");
        platformWallet = _newPlatformWallet;
    }

    receive() external payable {
        revert("Direct ETH transfers not allowed");
    }
}