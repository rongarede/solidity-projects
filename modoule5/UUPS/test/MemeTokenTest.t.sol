// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "lib/openzeppelin-contracts/lib/forge-std/src/Test.sol";
import "../src/MemeFactory.sol";
import "../src/MemeToken.sol";

contract MemeTokenTest is Test {
    MemeFactory public factory;
    MemeToken public token;
    address public deployer;
    address public user1;
    address public user2;

    event MemeTokenDeployed(
        address indexed tokenAddress,
        address indexed issuer,
        string symbol,
        uint256 totalSupply,
        uint256 perMint,
        uint256 price
    );

    event MemeMinted(
        address indexed tokenAddress,
        address indexed buyer,
        uint256 amount,
        uint256 totalCost,
        uint256 platformFee,
        uint256 issuerRevenue
    );

    function setUp() public {
        deployer = makeAddr("deployer");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.deal(user1, 100000 ether);
        vm.deal(user2, 100000 ether);

        vm.startPrank(deployer);
        factory = new MemeFactory();
        vm.stopPrank();
    }

    function testDeployMemeToken() public {
        vm.startPrank(deployer);
        
        vm.expectEmit(false, true, false, true);
        emit MemeTokenDeployed(
            address(0), // 地址会动态生成，所以不检查
            deployer,
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );

        address tokenAddress = factory.deployMeme(
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );

        assertNotEq(tokenAddress, address(0));
        
        token = MemeToken(tokenAddress);
        assertEq(token.name(), "MemeTEST");
        assertEq(token.symbol(), "TEST");
        assertEq(token.maxTotalSupply(), 1000 * 10**18);
        assertEq(token.perMint(), 10 * 10**18);
        assertEq(token.price(), 10);
        assertEq(token.issuer(), deployer);
        assertEq(token.totalMinted(), 0);
        assertFalse(token.isMaxSupplyReached());

        vm.stopPrank();
    }

    function testMintMemeToken() public {
        // 先部署代币
        vm.prank(deployer);
        address tokenAddress = factory.deployMeme(
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );
        token = MemeToken(tokenAddress);

        // 用户铸造代币
        uint256 mintAmount = 5 * 10**18;
        uint256 totalCost = mintAmount * 10; // 5*10^18 * 10 = 5*10^19
        uint256 platformFee = (totalCost * 100) / 10000; // 1%
        uint256 issuerRevenue = totalCost - platformFee;

        vm.expectEmit(true, true, false, true);
        emit MemeMinted(
            tokenAddress,
            user1,
            mintAmount,
            totalCost,
            platformFee,
            issuerRevenue
        );

        vm.prank(user1);
        factory.mintMeme{value: totalCost}(tokenAddress, mintAmount);

        // 检查结果
        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalMinted(), mintAmount);
        assertEq(factory.platformRevenue(), platformFee);
    }

    function testMintExceedsPerMintLimit() public {
        vm.prank(deployer);
        address tokenAddress = factory.deployMeme(
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );

        uint256 mintAmount = 15 * 10**18; // 超过 perMint 限制
        uint256 totalCost = mintAmount * 10;

        vm.prank(user1);
        vm.expectRevert("MemeFactory: amount exceeds perMint limit");
        factory.mintMeme{value: totalCost}(tokenAddress, mintAmount);
    }

    function testMintInsufficientPayment() public {
        vm.prank(deployer);
        address tokenAddress = factory.deployMeme(
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );

        uint256 mintAmount = 5 * 10**18;
        uint256 requiredCost = mintAmount * 10;
        uint256 insufficientCost = requiredCost - 1; // 少1 wei

        vm.prank(user1);
        vm.expectRevert("MemeFactory: insufficient payment");
        factory.mintMeme{value: insufficientCost}(tokenAddress, mintAmount);
    }

    function testUpdatePrice() public {
        vm.prank(deployer);
        address tokenAddress = factory.deployMeme(
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );
        token = MemeToken(tokenAddress);

        // 发行者更新价格
        uint256 newPrice = 20;
        vm.prank(deployer);
        token.updatePrice(newPrice);

        assertEq(token.price(), newPrice);
    }

    function testUpdatePriceUnauthorized() public {
        vm.prank(deployer);
        address tokenAddress = factory.deployMeme(
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );
        token = MemeToken(tokenAddress);

        // 非发行者尝试更新价格
        vm.prank(user1);
        vm.expectRevert("MemeToken: only issuer can update price");
        token.updatePrice(20);
    }

    function testWithdrawPlatformRevenue() public {
        // 先部署代币并铸造一些代币产生收益
        vm.prank(deployer);
        address tokenAddress = factory.deployMeme(
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );

        uint256 mintAmount = 5 * 10**18;
        uint256 totalCost = mintAmount * 10;

        vm.prank(user1);
        factory.mintMeme{value: totalCost}(tokenAddress, mintAmount);

        uint256 platformRevenue = factory.platformRevenue();
        uint256 deployerBalanceBefore = deployer.balance;

        vm.prank(deployer);
        factory.withdrawPlatformRevenue();

        assertEq(factory.platformRevenue(), 0);
        assertEq(deployer.balance, deployerBalanceBefore + platformRevenue);
    }

    function testGetTokenInfo() public {
        vm.prank(deployer);
        address tokenAddress = factory.deployMeme(
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );

        (
            string memory name,
            string memory symbol,
            uint256 totalSupply,
            uint256 maxTotalSupply,
            uint256 perMint,
            uint256 price,
            address issuer,
            bool isMaxSupplyReached
        ) = factory.getTokenInfo(tokenAddress);

        assertEq(name, "MemeTEST");
        assertEq(symbol, "TEST");
        assertEq(totalSupply, 0);
        assertEq(maxTotalSupply, 1000 * 10**18);
        assertEq(perMint, 10 * 10**18);
        assertEq(price, 10);
        assertEq(issuer, deployer);
        assertFalse(isMaxSupplyReached);
    }

    function testMaxSupplyReached() public {
        vm.prank(deployer);
        address tokenAddress = factory.deployMeme(
            "TEST",
            100 * 10**18, // 较小的总供应量
            10 * 10**18,
            10
        );
        token = MemeToken(tokenAddress);

        // 铸造到最大供应量
        uint256 mintPerRound = 10 * 10**18;
        uint256 costPerRound = mintPerRound * 10;
        for (uint i = 0; i < 10; i++) {
            vm.prank(user1);
            factory.mintMeme{value: costPerRound}(tokenAddress, mintPerRound);
        }

        assertTrue(token.isMaxSupplyReached());
        assertEq(token.totalMinted(), 100 * 10**18);

        // 尝试再次铸造应该失败
        vm.prank(user1);
        vm.expectRevert("MemeFactory: max supply reached");
        factory.mintMeme{value: costPerRound}(tokenAddress, mintPerRound);
    }

    function testTokenTransfer() public {
        vm.prank(deployer);
        address tokenAddress = factory.deployMeme(
            "TEST",
            1000 * 10**18,
            10 * 10**18,
            10
        );
        token = MemeToken(tokenAddress);

        // 用户1铸造代币
        uint256 mintAmount = 5 * 10**18;
        uint256 mintCost = mintAmount * 10;
        vm.prank(user1);
        factory.mintMeme{value: mintCost}(tokenAddress, mintAmount);

        // 用户1转账给用户2
        uint256 transferAmount = 2 * 10**18;
        vm.prank(user1);
        token.transfer(user2, transferAmount);

        assertEq(token.balanceOf(user1), mintAmount - transferAmount);
        assertEq(token.balanceOf(user2), transferAmount);
    }

    function testRevertDeployWithZeroSupply() public {
        vm.prank(deployer);
        vm.expectRevert("MemeFactory: totalSupply must be greater than 0");
        factory.deployMeme(
            "TEST",
            0, // 零供应量应该失败
            10 * 10**18,
            10
        );
    }

    function testRevertDeployWithEmptySymbol() public {
        vm.prank(deployer);
        vm.expectRevert("MemeFactory: symbol cannot be empty");
        factory.deployMeme(
            "", // 空符号应该失败
            1000 * 10**18,
            10 * 10**18,
            10
        );
    }

    function testDeployedTokensTracking() public {
        vm.startPrank(deployer);
        
        address token1 = factory.deployMeme("TOKEN1", 1000 * 10**18, 10 * 10**18, 10);
        address token2 = factory.deployMeme("TOKEN2", 2000 * 10**18, 20 * 10**18, 20);
        
        assertEq(factory.getDeployedTokensCount(), 2);
        
        address[] memory tokens = factory.getDeployedTokens(0, 1);
        assertEq(tokens.length, 2);
        assertEq(tokens[0], token1);
        assertEq(tokens[1], token2);
        
        vm.stopPrank();
    }
}