const hre = require("hardhat");

async function main() {
    const [deployer] = await hre.ethers.getSigners();
    console.log("Deploying contracts with the account:", deployer.address);

    // Deploy factory
    const Factory = await hre.ethers.getContractFactory("ScholarshipFactory");
    const factory = await Factory.deploy();
    await factory.deployed();
    console.log("Factory deployed to:", factory.address);

    // Generate Merkle tree and proofs
    console.log("Generating Merkle tree and proofs...");
    await hre.run("generateMerkleProofs");

    // Read merkle data
    const merkleData = require("../merkle_data.json");
    console.log("Merkle root:", merkleData.merkleRoot);

    // Sepolia ETH/USD price feed address
    const sepoliaPriceFeed = "0x694AA1769357215DE4FAC081bf1f309aDC325306";

    // Create a dispenser instance
    const tx = await factory.createDispenser(
        deployer.address, // director
        merkleData.merkleRoot,
        500, // $5.00
        sepoliaPriceFeed
    );
    const receipt = await tx.wait();
    const event = receipt.events.find(e => e.event === "DispenserCreated");
    const dispenserAddress = event.args.dispenser;
    console.log("Dispenser deployed to:", dispenserAddress);

    // Verify contracts on Etherscan
    console.log("Waiting for block confirmations...");
    await factory.deployTransaction.wait(5);

    console.log("Verifying contracts on Etherscan...");
    await hre.run("verify:verify", {
        address: factory.address,
        constructorArguments: [],
    });

    await hre.run("verify:verify", {
        address: dispenserAddress,
        constructorArguments: [
            deployer.address,
            merkleData.merkleRoot,
            500,
            sepoliaPriceFeed
        ],
    });

    console.log("Deployment complete!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 