// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "../src/MyToken.sol";

contract MyTokenTest is Test {
    MyToken public token;
    address public owner;
    address public user1;
    address public user2;

    uint256 public constant INITIAL_SUPPLY = 1_000_000 * 10**18;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.prank(owner);
        token = new MyToken("MyToken", "MTK", INITIAL_SUPPLY, owner);
    }

    function testInitialState() public {
        assertEq(token.name(), "MyToken");
        assertEq(token.symbol(), "MTK");
        assertEq(token.decimals(), 18);
        assertEq(token.totalSupply(), INITIAL_SUPPLY);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY);
        assertEq(token.owner(), owner);
    }

    function testMint() public {
        uint256 mintAmount = 1000 * 10**18;
        
        vm.prank(owner);
        token.mint(user1, mintAmount);

        assertEq(token.balanceOf(user1), mintAmount);
        assertEq(token.totalSupply(), INITIAL_SUPPLY + mintAmount);
    }

    function testMintOnlyOwner() public {
        uint256 mintAmount = 1000 * 10**18;
        
        vm.prank(user1);
        vm.expectRevert();
        token.mint(user2, mintAmount);
    }

    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**18;
        
        vm.prank(owner);
        token.transfer(user1, transferAmount);

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - transferAmount);
        assertEq(token.balanceOf(user1), transferAmount);
    }

    function testApproveAndTransferFrom() public {
        uint256 amount = 1000 * 10**18;
        
        vm.prank(owner);
        token.approve(user1, amount);

        assertEq(token.allowance(owner, user1), amount);

        vm.prank(user1);
        token.transferFrom(owner, user2, amount);

        assertEq(token.balanceOf(owner), INITIAL_SUPPLY - amount);
        assertEq(token.balanceOf(user2), amount);
        assertEq(token.allowance(owner, user1), 0);
    }

    function testOwnershipTransfer() public {
        vm.prank(owner);
        token.transferOwnership(user1);

        assertEq(token.owner(), user1);
    }

    function testFuzzMint(uint256 amount) public {
        vm.assume(amount <= type(uint256).max - INITIAL_SUPPLY);
        
        uint256 balanceBefore = token.balanceOf(user1);
        uint256 totalSupplyBefore = token.totalSupply();

        vm.prank(owner);
        token.mint(user1, amount);

        assertEq(token.balanceOf(user1), balanceBefore + amount);
        assertEq(token.totalSupply(), totalSupplyBefore + amount);
    }
}