// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/MultiSigWallet.sol";

contract MultiSigWalletTest is Test {
    MultiSigWallet public wallet;
    address[] public owners;
    uint256 public threshold = 2;

    address owner1 = makeAddr("owner1");
    address owner2 = makeAddr("owner2");
    address owner3 = makeAddr("owner3");
    address nonOwner = makeAddr("nonOwner");
    address recipient = makeAddr("recipient");

    function setUp() public {
        owners = [owner1, owner2, owner3];
        wallet = new MultiSigWallet(owners, threshold);
        
        // 给钱包转入一些以太币
        vm.deal(address(wallet), 10 ether);
    }

    function test_Constructor() public {
        assertEq(wallet.threshold(), threshold);
        assertEq(wallet.getOwners().length, 3);
        assertTrue(wallet.isOwner(owner1));
        assertTrue(wallet.isOwner(owner2));
        assertTrue(wallet.isOwner(owner3));
        assertFalse(wallet.isOwner(nonOwner));
    }

    function test_SubmitTransaction() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        
        assertEq(wallet.getTransactionCount(), 1);
        
        (address to, uint256 value, bytes memory data, bool executed, uint256 confirmations) = 
            wallet.getTransaction(0);
        
        assertEq(to, recipient);
        assertEq(value, 1 ether);
        assertEq(data, "");
        assertFalse(executed);
        assertEq(confirmations, 0);
    }

    function test_SubmitTransactionRevertNotOwner() public {
        vm.prank(nonOwner);
        vm.expectRevert(MultiSigWallet.NotOwner.selector);
        wallet.submitTransaction(recipient, 1 ether, "");
    }

    function test_ConfirmTransaction() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        
        assertTrue(wallet.isTransactionConfirmed(0, owner1));
        (, , , , uint256 confirmations) = wallet.getTransaction(0);
        assertEq(confirmations, 1);
    }

    function test_ConfirmTransactionRevertAlreadyConfirmed() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TransactionAlreadyConfirmed.selector);
        wallet.confirmTransaction(0);
    }

    function test_ExecuteTransaction() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        
        vm.prank(owner2);
        wallet.confirmTransaction(0);
        
        uint256 recipientBalanceBefore = recipient.balance;
        uint256 walletBalanceBefore = address(wallet).balance;
        
        wallet.executeTransaction(0);
        
        assertEq(recipient.balance, recipientBalanceBefore + 1 ether);
        assertEq(address(wallet).balance, walletBalanceBefore - 1 ether);
        
        (, , , bool executed, ) = wallet.getTransaction(0);
        assertTrue(executed);
    }

    function test_ExecuteTransactionRevertInsufficientConfirmations() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        
        vm.expectRevert(MultiSigWallet.InsufficientConfirmations.selector);
        wallet.executeTransaction(0);
    }

    function test_ExecuteTransactionRevertAlreadyExecuted() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        
        vm.prank(owner2);
        wallet.confirmTransaction(0);
        
        wallet.executeTransaction(0);
        
        vm.expectRevert(MultiSigWallet.TransactionAlreadyExecuted.selector);
        wallet.executeTransaction(0);
    }

    function test_RevokeConfirmation() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        wallet.confirmTransaction(0);
        
        vm.prank(owner1);
        wallet.revokeConfirmation(0);
        
        assertFalse(wallet.isTransactionConfirmed(0, owner1));
        (, , , , uint256 confirmations) = wallet.getTransaction(0);
        assertEq(confirmations, 0);
    }

    function test_RevokeConfirmationRevertNotConfirmed() public {
        vm.prank(owner1);
        wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        vm.expectRevert(MultiSigWallet.TransactionNotConfirmed.selector);
        wallet.revokeConfirmation(0);
    }

    function test_GetBalance() public {
        assertEq(wallet.getBalance(), 10 ether);
    }

    function test_ReceiveEther() public {
        uint256 balanceBefore = address(wallet).balance;
        
        vm.deal(address(this), 1 ether);
        (bool success, ) = address(wallet).call{value: 1 ether}("");
        
        assertTrue(success);
        assertEq(address(wallet).balance, balanceBefore + 1 ether);
    }

    function test_Events() public {
        vm.prank(owner1);
        vm.expectEmit(true, true, true, true);
        emit MultiSigWallet.Submit(owner1, 0, recipient, 1 ether, "");
        wallet.submitTransaction(recipient, 1 ether, "");
        
        vm.prank(owner1);
        vm.expectEmit(true, true, false, false);
        emit MultiSigWallet.Confirm(owner1, 0);
        wallet.confirmTransaction(0);
        
        vm.prank(owner2);
        wallet.confirmTransaction(0);
        
        vm.expectEmit(true, true, false, false);
        emit MultiSigWallet.Execute(address(this), 0);
        wallet.executeTransaction(0);
    }

    function test_AddOwner() public {
        address newOwner = makeAddr("newOwner");
        
        wallet.addOwner(newOwner);
        
        assertTrue(wallet.isOwner(newOwner));
        assertEq(wallet.getOwners().length, 4);
    }

    function test_AddOwnerRevertNotOwner() public {
        address newOwner = makeAddr("newOwner");
        
        vm.prank(owner1);
        vm.expectRevert();
        wallet.addOwner(newOwner);
    }

    function test_RemoveOwner() public {
        wallet.removeOwner(owner3);
        
        assertFalse(wallet.isOwner(owner3));
        assertEq(wallet.getOwners().length, 2);
    }

    function test_RemoveOwnerRevertInsufficientOwners() public {
        wallet.removeOwner(owner3);
        
        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector);
        wallet.removeOwner(owner2);
    }

    function test_UpdateThreshold() public {
        wallet.updateThreshold(3);
        
        assertEq(wallet.threshold(), 3);
    }

    function test_UpdateThresholdRevertInvalidThreshold() public {
        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector);
        wallet.updateThreshold(0);
        
        vm.expectRevert(MultiSigWallet.InvalidThreshold.selector);
        wallet.updateThreshold(4);
    }
}