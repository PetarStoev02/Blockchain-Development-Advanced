# Micro-Scholarship Dispenser

A smart contract system for distributing small ETH scholarships to verified students using Merkle proofs and Chainlink price feeds.

## Features

- Minimal proxy factory pattern for gas-efficient deployments
- Merkle tree-based allowlist for student verification
- Chainlink price feed integration for USD-to-ETH conversion
- One-time claim per student
- Director can withdraw leftover funds
- Maximum stipend of $5.00 USD

## Setup

### Prerequisites
- Node.js and npm
- Foundry (forge, cast, anvil)

### Installation

1. Install Foundry dependencies:
```bash
forge install
```

2. Install npm dependencies:
```bash
npm install
```

3. Create a `.env` file with your configuration:
```
PRIVATE_KEY=your_private_key
SEPOLIA_RPC_URL=your_sepolia_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## Development

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

## Deployment

1. Deploy to Sepolia using Hardhat:
```bash
npx hardhat run scripts/deploy.js --network sepolia
```

2. Generate Merkle proofs:
```bash
npx hardhat run scripts/generateMerkleProofs.js
```

## Contract Architecture

- `ScholarshipFactory`: Deploys minimal proxies of the ScholarshipDispenser
- `ScholarshipDispenser`: Main contract that handles scholarship distribution
- `MockV3Aggregator`: Mock Chainlink price feed for testing

## Usage

1. Deploy the factory contract
2. Create a dispenser instance with:
   - Director address
   - Merkle root of approved students
   - USD stipend amount in cents
   - Chainlink price feed address
3. Fund the dispenser with ETH
4. Students can claim their stipend by providing their Merkle proof
5. Director can withdraw any leftover funds

## Security

- Merkle proofs ensure only approved students can claim
- One-time claim per address
- Maximum stipend limit of $5.00
- Only director can withdraw leftover funds

## Testing

The test suite covers:
- Successful stipend claims
- Invalid Merkle proofs
- Double-claim prevention
- Director withdrawal functionality

Both Hardhat and Foundry test suites are provided:
- `test/ScholarshipDispenser.test.js` (Hardhat) - Uses mock price feed
- `test/ScholarshipDispenser.t.sol` (Foundry) - Uses real Chainlink price feed

## License

MIT
