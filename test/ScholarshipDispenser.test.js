const { expect } = require("chai");
const { ethers } = require("hardhat");
const { keccak256, defaultAbiCoder } = ethers.utils;

describe("ScholarshipDispenser", function () {
    let factory;
    let dispenser;
    let owner;
    let director;
    let student;
    let priceFeed;
    let merkleRoot;
    let merkleProof;

    beforeEach(async function () {
        [owner, director, student] = await ethers.getSigners();

        // Deploy mock price feed
        const MockPriceFeed = await ethers.getContractFactory("MockV3Aggregator");
        priceFeed = await MockPriceFeed.deploy(8, 200000000000); // $2000 per ETH

        // Deploy factory
        const Factory = await ethers.getContractFactory("ScholarshipFactory");
        factory = await Factory.deploy();

        // Generate Merkle tree
        const leaf = keccak256(defaultAbiCoder.encode(["address"], [student.address]));
        merkleRoot = leaf; // For single leaf, the root is the leaf itself
        merkleProof = []; // Empty proof for single leaf

        // Create dispenser
        const tx = await factory.createDispenser(
            director.address,
            merkleRoot,
            500, // $5.00
            priceFeed.address
        );
        const receipt = await tx.wait();
        const event = receipt.events.find(e => e.event === "DispenserCreated");
        dispenser = await ethers.getContractAt("ScholarshipDispenser", event.args.dispenser);
    });

    it("Should allow student to claim stipend", async function () {
        // Fund the dispenser
        await director.sendTransaction({
            to: dispenser.address,
            value: ethers.utils.parseEther("1.0")
        });

        // Claim stipend
        await expect(dispenser.connect(student).claimStipend(merkleProof))
            .to.emit(dispenser, "StipendClaimed")
            .withArgs(student.address, ethers.utils.parseEther("0.0025")); // $5.00 at $2000/ETH

        // Verify student can't claim again
        await expect(dispenser.connect(student).claimStipend(merkleProof))
            .to.be.revertedWith("Already claimed");
    });

    it("Should allow director to withdraw leftover funds", async function () {
        // Fund the dispenser
        await director.sendTransaction({
            to: dispenser.address,
            value: ethers.utils.parseEther("1.0")
        });

        // Withdraw leftover
        const initialBalance = await ethers.provider.getBalance(director.address);
        await dispenser.connect(director).withdrawLeftover();
        const finalBalance = await ethers.provider.getBalance(director.address);

        expect(finalBalance).to.be.gt(initialBalance);
    });

    it("Should reject invalid Merkle proofs", async function () {
        const invalidProof = [ethers.utils.randomBytes(32)];
        
        await expect(dispenser.connect(student).claimStipend(invalidProof))
            .to.be.revertedWith("Invalid proof");
    });
}); 