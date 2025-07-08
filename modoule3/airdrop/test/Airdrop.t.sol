// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "forge-std/Test.sol";
import "openzeppelin-contracts/contracts/utils/cryptography/MerkleProof.sol";
import "../src/Airdrop.sol";
import "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// Mock ERC20 token for testing
contract MockERC20 is ERC20 {
    constructor() ERC20("Mock Token", "MTK") {}

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }
}

contract AirdropDistributorTest is Test {
    AirdropDistributor public airdrop;
    MockERC20 public token;

    bytes32 public merkleRoot;
    
    address public owner;
    address public user1 = vm.addr(1);
    address public user2 = vm.addr(2);
    address public user3 = vm.addr(3);

    uint256 public amount1 = 100 * 1e18;
    uint256 public amount2 = 200 * 1e18;
    uint256 public amount3 = 300 * 1e18;

    bytes32[] public proof1;
    bytes32[] public proof2;
    bytes32[] public proof3;

    function setUp() public {
        owner = address(this);
        vm.label(owner, "Owner");
        vm.label(user1, "User1");
        vm.label(user2, "User2");
        vm.label(user3, "User3");

        // 1. Deploy Mock Token
        token = new MockERC20();

        // 2. Create Merkle Tree and Proofs
        bytes32[] memory leaves = new bytes32[](3);
        leaves[0] = keccak256(abi.encodePacked(user1, amount1));
        leaves[1] = keccak256(abi.encodePacked(user2, amount2));
        leaves[2] = keccak256(abi.encodePacked(user3, amount3));

        // Build the Merkle Tree, sorting pairs before hashing as per OpenZeppelin's standard
        bytes32 node12 = _hashPair(leaves[0], leaves[1]);
        merkleRoot = _hashPair(node12, leaves[2]);

        // Generate proofs
        proof1 = new bytes32[](2);
        proof1[0] = leaves[1];
        proof1[1] = leaves[2];

        proof2 = new bytes32[](2);
        proof2[0] = leaves[0];
        proof2[1] = leaves[2];
        
        proof3 = new bytes32[](1);
        proof3[0] = node12;

        // 3. Deploy AirdropDistributor
        uint256 maxClaimable = (amount1 + amount2 + amount3);
        airdrop = new AirdropDistributor(address(token), merkleRoot, maxClaimable);

        // 4. Fund the airdrop contract
        token.mint(address(airdrop), maxClaimable);
    }

    function test_Claim_Succeeds() public {
        uint256 balanceBefore = token.balanceOf(user1);
        assertEq(balanceBefore, 0);

        vm.prank(user1);
        airdrop.claimWithMerkle(user1, amount1, proof1);

        uint256 balanceAfter = token.balanceOf(user1);
        assertEq(balanceAfter, amount1);
        assertTrue(airdrop.hasClaimed(user1));
    }

    function test_Claim_Fails_If_Already_Claimed() public {
        // First claim
        vm.prank(user1);
        airdrop.claimWithMerkle(user1, amount1, proof1);

        // Second claim should fail
        vm.prank(user1);
        vm.expectRevert(AirdropDistributor.AlreadyClaimed.selector);
        airdrop.claimWithMerkle(user1, amount1, proof1);
    }

    function test_Claim_Fails_If_Invalid_Proof() public {
        bytes32[] memory invalidProof = new bytes32[](1);
        invalidProof[0] = keccak256(abi.encodePacked("invalid proof"));

        vm.prank(user1);
        vm.expectRevert(AirdropDistributor.InvalidProof.selector);
        airdrop.claimWithMerkle(user1, amount1, invalidProof);
    }

    function test_Claim_Fails_If_Paused() public {
        airdrop.pause();

        vm.prank(user1);
        // Recent OpenZeppelin versions use the "EnforcedPause" custom error.
        vm.expectRevert(abi.encodeWithSignature("EnforcedPause()"));
        airdrop.claimWithMerkle(user1, amount1, proof1);
    }

    function test_Owner_Can_Update_Merkle_Root() public {
        bytes32 newRoot = keccak256(abi.encodePacked("new root"));
        airdrop.updateMerkleRoot(newRoot);
        assertEq(airdrop.merkleRoot(), newRoot);
    }

    function test_Owner_Can_Withdraw_Tokens() public {
        uint256 balanceBefore = token.balanceOf(address(airdrop));
        uint256 ownerBalanceBefore = token.balanceOf(owner);

        airdrop.withdrawTokens(owner, balanceBefore);

        uint256 balanceAfter = token.balanceOf(address(airdrop));
        uint256 ownerBalanceAfter = token.balanceOf(owner);

        assertEq(balanceAfter, 0);
        assertEq(ownerBalanceAfter, ownerBalanceBefore + balanceBefore);
    }

    // Helper function to mimic OpenZeppelin's sorted hashing
    function _hashPair(bytes32 a, bytes32 b) private pure returns (bytes32) {
        if (a < b) {
            return keccak256(abi.encodePacked(a, b));
        } else {
            return keccak256(abi.encodePacked(b, a));
        }
    }
}
