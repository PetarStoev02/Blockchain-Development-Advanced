// SPDX-License-Identifier: MIT
pragma solidity ^0.8.26;

import {Script, console} from "forge-std/Script.sol";
import {RaffleHouse} from "../src/RaffleHouse.sol";

contract RaffleHouseScript is Script {
    RaffleHouse public raffleHouse;
    address public constant SEPOLIA_RAFFLE_HOUSE = 0xd249D95013B14749DABA8e82025612d480e7ef89;

    function setUp() public {}

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        // Deploy RaffleHouse
        raffleHouse = new RaffleHouse();

        // Create an example raffle
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 24 hours;
        uint256 ticketPrice = 0.1 ether;

        raffleHouse.createRaffle(
            ticketPrice,
            startTime,
            endTime,
            "Test Raffle",
            "TEST"
        );

        console.log("RaffleHouse deployed at:", address(raffleHouse));
        console.log("First raffle created with ID: 0");
        console.log("Sepolia RaffleHouse address:", SEPOLIA_RAFFLE_HOUSE);

        vm.stopBroadcast();
    }
} 