// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "../lib/forge-std/src/Test.sol";
import "../lib/forge-std/src/console.sol";
import "../contracts/ScholarshipFactory.sol";
import "../contracts/ScholarshipDispenser.sol";

contract ScholarshipDispenserTest is Test {
    ScholarshipFactory public factory;
    ScholarshipDispenser public dispenser;
    address public director;
    address public student;
    bytes32 public merkleRoot;
    bytes32[] public merkleProof;
    
    // Sepolia ETH/USD price feed address
    address constant SEPOLIA_ETH_USD_PRICE_FEED = 0x694AA1769357215DE4FAC081bf1f309aDC325306;

    function setUp() public {
        director = makeAddr("director");
        student = makeAddr("student");
        vm.deal(director, 10 ether);

        // Deploy factory
        factory = new ScholarshipFactory();

        // Generate Merkle tree
        bytes32 node = keccak256(abi.encodePacked(student));
        merkleRoot = node; // For single leaf, the root is the leaf itself
        merkleProof = new bytes32[](0); // Empty proof for single leaf

        // Create dispenser with real price feed
        vm.prank(director);
        address dispenserAddress = factory.createDispenser(
            director,
            merkleRoot,
            500, // $5.00
            SEPOLIA_ETH_USD_PRICE_FEED
        );
        
        // Cast to payable since the contract has a payable fallback
        dispenser = ScholarshipDispenser(payable(dispenserAddress));

        // Fund the dispenser
        vm.deal(address(dispenser), 1 ether);
        
        // Debug prints
        console.log("Factory address:", address(factory));
        console.log("Implementation address:", factory.implementation());
        console.log("Dispenser address:", address(dispenser));
        console.log("Director address:", director);
        console.log("Student address:", student);
        console.log("Dispenser balance:", address(dispenser).balance);
    }

    function test_ClaimStipend() public {
        uint256 initialBalance = student.balance;
        console.log("Initial student balance:", initialBalance);
        
        vm.prank(student);
        dispenser.claimStipend(merkleProof);

        // Verify the student received some ETH
        uint256 finalBalance = student.balance;
        console.log("Final student balance:", finalBalance);
        assertGt(finalBalance, initialBalance);
        
        // Verify student can't claim again
        vm.prank(student);
        vm.expectRevert("Already claimed");
        dispenser.claimStipend(merkleProof);
    }

    function test_WithdrawLeftover() public {
        uint256 initialBalance = director.balance;
        console.log("Initial director balance:", initialBalance);
        
        vm.prank(director);
        dispenser.withdrawLeftover();
        
        uint256 finalBalance = director.balance;
        console.log("Final director balance:", finalBalance);
        assertGt(finalBalance, initialBalance);
    }

    function test_InvalidMerkleProof() public {
        bytes32[] memory invalidProof = new bytes32[](1);
        invalidProof[0] = bytes32(uint256(1));

        vm.prank(student);
        vm.expectRevert("Invalid proof");
        dispenser.claimStipend(invalidProof);
    }

    function test_OnlyDirectorCanWithdraw() public {
        vm.prank(student);
        vm.expectRevert("Only director");
        dispenser.withdrawLeftover();
    }

    function test_MaxStipendLimit() public {
        vm.prank(director);
        vm.expectRevert("Stipend too large");
        factory.createDispenser(
            director,
            merkleRoot,
            501, // $5.01 (exceeds limit)
            SEPOLIA_ETH_USD_PRICE_FEED
        );
    }
} 