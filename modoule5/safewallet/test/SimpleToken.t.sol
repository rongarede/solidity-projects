// SPDX-License-Identifier: MIT
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {SimpleToken} from "../src/SimpleToken.sol";

contract SimpleTokenTest is Test {
    SimpleToken public token;
    address public owner = address(this);
    address public user1 = address(0x1);
    address public user2 = address(0x2);
    
    uint256 public constant INITIAL_SUPPLY = 1000000;

    function setUp() public {
        token = new SimpleToken("Test Token", "TEST", INITIAL_SUPPLY);
    }

    function testInitialSupply() public {
        assertEq(token.totalSupply(), INITIAL_SUPPLY * 10**token.decimals());
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY * 10**token.decimals());
    }

    function testTokenMetadata() public {
        assertEq(token.name(), "Test Token");
        assertEq(token.symbol(), "TEST");
        assertEq(token.decimals(), 18);
    }

    function testTransfer() public {
        uint256 transferAmount = 1000 * 10**token.decimals();
        
        assertTrue(token.transfer(user1, transferAmount));
        assertEq(token.balanceOf(user1), transferAmount);
        assertEq(token.balanceOf(owner), INITIAL_SUPPLY * 10**token.decimals() - transferAmount);
    }

    function testApproveAndTransferFrom() public {
        uint256 approveAmount = 5000 * 10**token.decimals();
        uint256 transferAmount = 2000 * 10**token.decimals();
        
        assertTrue(token.approve(user1, approveAmount));
        assertEq(token.allowance(owner, user1), approveAmount);
        
        vm.prank(user1);
        assertTrue(token.transferFrom(owner, user2, transferAmount));
        
        assertEq(token.balanceOf(user2), transferAmount);
        assertEq(token.allowance(owner, user1), approveAmount - transferAmount);
    }

    function testRevertWhenTransferInsufficientBalance() public {
        uint256 transferAmount = INITIAL_SUPPLY * 10**token.decimals() + 1;
        
        vm.expectRevert();
        token.transfer(user1, transferAmount);
    }

    function testRevertWhenTransferFromInsufficientAllowance() public {
        uint256 transferAmount = 1000 * 10**token.decimals();
        
        vm.expectRevert();
        vm.prank(user1);
        token.transferFrom(owner, user2, transferAmount);
    }
}