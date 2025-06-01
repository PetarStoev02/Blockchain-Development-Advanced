const { ethers } = require("hardhat");
const fs = require("fs");
const path = require("path");

async function main() {
    // Sample student addresses (replace with actual addresses)
    const students = [
        "0x70997970C51812dc3A010C7d01b50e0d17dc79C8",
        "0x3C44CdDdB6a900fa2b585dd299e03d12FA4293BC",
        "0x90F79bf6EB2c4f870365E785982E1f101E93b906",
        "0x15d34AAf54267DB7D7c367839AAf71A00a2C6A65",
        "0x9965507D1a55bcC2695C58ba16FB37d819B0A4dc"
    ];

    // Create leaves (hashed addresses)
    const leaves = students.map(addr => 
        ethers.utils.keccak256(ethers.utils.defaultAbiCoder.encode(["address"], [addr]))
    );

    // Generate Merkle tree
    const merkleTree = new ethers.utils.MerkleTree(leaves, ethers.utils.keccak256, { sortPairs: true });
    const root = merkleTree.getHexRoot();

    // Generate proofs for each student
    const proofs = students.map((student, index) => {
        const leaf = leaves[index];
        const proof = merkleTree.getHexProof(leaf);
        return {
            address: student,
            proof: proof
        };
    });

    // Create output object
    const output = {
        merkleRoot: root,
        students: proofs
    };

    // Write to file
    const outputPath = path.join(__dirname, "../merkle_data.json");
    fs.writeFileSync(outputPath, JSON.stringify(output, null, 2));

    console.log("Merkle root:", root);
    console.log("Proofs generated and saved to merkle_data.json");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    }); 