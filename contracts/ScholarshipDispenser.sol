// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface AggregatorV3Interface {
    function latestRoundData()
        external
        view
        returns (
            uint80 roundId,
            int256 answer,
            uint256 startedAt,
            uint256 updatedAt,
            uint80 answeredInRound
        );
}

contract ScholarshipDispenser {
    address public director;
    bytes32 public merkleRoot;
    uint256 public usdStipendCents;
    AggregatorV3Interface public priceFeed;
    
    mapping(address => bool) public claimed;
    bool private initialized;
    
    event StipendClaimed(address indexed student, uint256 amount);
    
    function initialize(
        address _director,
        bytes32 _merkleRoot,
        uint256 _usdStipendCents,
        address _priceFeed
    ) external {
        require(!initialized, "Already initialized");
        require(_director != address(0), "Invalid director address");
        require(_priceFeed != address(0), "Invalid price feed address");
        require(_usdStipendCents <= 500, "Stipend too large"); // Max $5.00
        
        director = _director;
        merkleRoot = _merkleRoot;
        usdStipendCents = _usdStipendCents;
        priceFeed = AggregatorV3Interface(_priceFeed);
        initialized = true;
    }
    
    function claimStipend(bytes32[] calldata merkleProof) external {
        require(initialized, "Not initialized");
        require(!claimed[msg.sender], "Already claimed");
        
        // Verify Merkle proof
        bytes32 node = keccak256(abi.encodePacked(msg.sender));
        
        // For single leaf case, the root should be the leaf itself
        if (merkleProof.length == 0) {
            require(node == merkleRoot, "Invalid proof");
        } else {
            require(
                verifyMerkleProof(merkleProof, merkleRoot, node),
                "Invalid proof"
            );
        }
        
        // Get latest ETH/USD price
        (, int256 price,,,) = priceFeed.latestRoundData();
        require(price > 0, "Invalid price");
        
        // Calculate wei amount (price is in 8 decimals, usdStipendCents is in cents)
        // Formula: (usdStipendCents * 1e18) / (price * 100)
        uint256 weiAmount = (usdStipendCents * 1e18) / (uint256(price) * 100);
        
        // Mark as claimed before transfer
        claimed[msg.sender] = true;
        
        // Transfer ETH
        (bool success, ) = msg.sender.call{value: weiAmount}("");
        require(success, "Transfer failed");
        
        emit StipendClaimed(msg.sender, weiAmount);
    }
    
    function verifyMerkleProof(
        bytes32[] calldata proof,
        bytes32 root,
        bytes32 leaf
    ) internal pure returns (bool) {
        bytes32 computedHash = leaf;

        for (uint256 i = 0; i < proof.length; i++) {
            bytes32 proofElement = proof[i];
            if (computedHash <= proofElement) {
                computedHash = keccak256(abi.encodePacked(computedHash, proofElement));
            } else {
                computedHash = keccak256(abi.encodePacked(proofElement, computedHash));
            }
        }

        return computedHash == root;
    }
    
    function withdrawLeftover() external {
        require(initialized, "Not initialized");
        require(msg.sender == director, "Only director");
        (bool success, ) = director.call{value: address(this).balance}("");
        require(success, "Transfer failed");
    }
    
    receive() external payable {}
} 