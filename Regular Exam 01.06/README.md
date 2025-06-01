# Micro-Scholarship Dispenser

A smart contract system for distributing small ETH scholarships to verified students using Merkle proofs and Chainlink price feeds.

## Description
This project serves as an advanced exploration into blockchain development, utilizing a dual-toolchain setup with both Hardhat and Foundry. It includes examples, scripts, and tests for developing and deploying smart contracts.

## Features
- Dual development environment support (Hardhat and Foundry)
- Minimal proxy factory pattern for gas-efficient deployments
- Merkle tree-based allowlist for student verification
- Chainlink price feed integration for USD-to-ETH conversion
- One-time claim per student
- Director can withdraw leftover funds
- Maximum stipend of $5.00 USD

## Technologies Used
- **Solidity** (v0.8.20)
- **Hardhat**
- **Foundry** (Forge and Cast)
- **OpenZeppelin Contracts**
- **OpenZeppelin Contracts Upgradeable**
- **Chainlink Contracts**
- **dotenv**

## Setup and Installation

### Prerequisites
- Node.js and npm or yarn
- Foundry (forge and cast). Follow installation instructions at [https://book.getfoundry.sh/getting-started/installation](https://book.getfoundry.sh/getting-started/installation)

### Installation Steps
1. Clone the repository:
   ```bash
   git clone https://github.com/PetarStoev02/Blockchain-Development-Advanced.git
   ```
2. Navigate to the project directory:
   ```bash
   cd "Regular Exam 01.06"
   ```
3. Install Node.js dependencies (for Hardhat):
   ```bash
   npm install
   ```
   or
   ```bash
   yarn install
   ```
4. Install Foundry dependencies (git submodules):
   ```bash
   forge install
   ```
5. Create a `.env` file in the project root based on `.env.example` (if provided), and fill in necessary environment variables (e.g., `SEPOLIA_RPC_URL`, `PRIVATE_KEY`, `ETHERSCAN_API_KEY`).

## Development and Usage

This project can be interacted with using both Hardhat and Foundry commands.

### Compilation
Using Hardhat:
```bash
npx hardhat compile
```
Using Foundry:
```bash
forge build
```

### Testing

The project includes two test suites:

1. Foundry Tests (Solidity):
```bash
forge test
```
These tests use the real Chainlink price feed on Sepolia testnet.

2. Hardhat Tests (JavaScript):
```bash
npx hardhat test
```
These tests use a mock price feed with a fixed price of $2000 per ETH.

For gas reporting:
```bash
forge test --gas-report
```

### Deployment
Deployment can be done using either Hardhat or Foundry scripts.

1. Deploy to Sepolia using Hardhat:
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

2. Generate Merkle proofs:
```bash
npx hardhat run scripts/generateMerkleProofs.js
```
Refer to the scripts in the `scripts/` directory for specific deployment instructions.

### Contract Interaction
1. Deploy the factory contract
2. Create a dispenser instance with:
   - Director address
   - Merkle root of approved students
   - USD stipend amount in cents
   - Chainlink price feed address
3. Fund the dispenser with ETH
4. Students can claim their stipend by providing their Merkle proof
5. Director can withdraw any leftover funds

## Project Structure
```
.
├── contracts/    # Smart contracts (Solidity)
├── scripts/    # Deployment and interaction scripts (JavaScript for Hardhat, Solidity for Foundry)
├── test/       # Tests (JavaScript for Hardhat, Solidity for Foundry)
├── lib/        # Foundry libraries/dependencies
├── hardhat.config.js # Hardhat configuration
├── foundry.toml  # Foundry configuration
├── package.json  # Node.js dependencies and scripts
├── README.md   # Project README
├── .gitignore
└── ...
```

## Contract Architecture

- `ScholarshipFactory`: Deploys minimal proxies of the ScholarshipDispenser
- `ScholarshipDispenser`: Main contract that handles scholarship distribution
- `MockV3Aggregator`: Mock Chainlink price feed for testing (used in Hardhat tests)

## Security

- Merkle proofs ensure only approved students can claim
- One-time claim per address
- Maximum stipend limit of $5.00
- Only director can withdraw leftover funds

## Contributing
Pull requests are welcome. For major changes, please open an issue first to discuss what you would like to change.

## License
MIT
