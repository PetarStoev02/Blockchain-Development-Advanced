// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {TicketNFT} from "../src/TicketNFT.sol";

contract TicketNFTScript is Script {
    TicketNFT public ticketNFT;
    address public constant SEPOLIA_TICKET_NFT = 0xA7a9Ce9749a541CFb1139Bd4C084e61536b774a2;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy TicketNFT
        ticketNFT = new TicketNFT("Test Raffle", "TEST");

        // Mint some example tickets
        ticketNFT.safeMint(msg.sender);
        ticketNFT.safeMint(msg.sender);

        console.log("TicketNFT deployed at:", address(ticketNFT));
        console.log("Total supply:", ticketNFT.totalSupply());
        console.log("Owner of token 0:", ticketNFT.ownerOf(0));
        console.log("Owner of token 1:", ticketNFT.ownerOf(1));
        console.log("Sepolia TicketNFT address:", SEPOLIA_TICKET_NFT);

        vm.stopBroadcast();
    }
} 