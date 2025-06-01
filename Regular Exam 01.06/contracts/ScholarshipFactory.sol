// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./ScholarshipDispenser.sol";

contract ScholarshipFactory {
    address public immutable implementation;
    
    event DispenserCreated(
        address indexed dispenser,
        address indexed director,
        bytes32 merkleRoot,
        uint256 usdStipendCents
    );
    
    constructor() {
        implementation = address(new ScholarshipDispenser());
    }
    
    function createDispenser(
        address director,
        bytes32 merkleRoot,
        uint256 usdStipendCents,
        address priceFeed
    ) external returns (address) {
        // Deploy minimal proxy
        address clone = _createClone(implementation);
        
        // Initialize the clone
        ScholarshipDispenser(payable(clone)).initialize(
            director,
            merkleRoot,
            usdStipendCents,
            priceFeed
        );
        
        emit DispenserCreated(
            clone,
            director,
            merkleRoot,
            usdStipendCents
        );
        
        return clone;
    }
    
    function _createClone(address target) internal returns (address result) {
        bytes20 targetBytes = bytes20(target);
        assembly {
            let clone := mload(0x40)
            mstore(clone, 0x3d602d80600a3d3981f3363d3d373d3d3d363d73000000000000000000000000)
            mstore(add(clone, 0x14), targetBytes)
            mstore(add(clone, 0x28), 0x5af43d82803e903d91602b57fd5bf30000000000000000000000000000000000)
            result := create(0, clone, 0x37)
        }
    }
} 