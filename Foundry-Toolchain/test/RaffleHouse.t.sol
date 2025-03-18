// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/**
 * ======================= IMPORTANT NOTICE =======================
 *
 * THIS CONTRACT USED IS FOR EDUCATIONAL PURPOSES ONLY.
 *
 * DO NOT USE IT IN PRODUCTION ENVIRONMENTS.
 * THE CODE MAY CONTAIN VULNERABILITIES AND IS PROVIDED
 * AS-IS FOR DEMONSTRATION AND LEARNING PURPOSES.
 * ================================================================
 */
import {Test} from "forge-std/Test.sol";
import {RaffleHouse} from "../src/RaffleHouse.sol";
import {TicketNFT} from "../src/TicketNFT.sol";
import {
    TicketPriceTooLow,
    RaffleAlreadyStarted,
    InvalidRaffleEndTime,
    InsufficientRaffleDuration,
    RaffleNotStarted,
    RaffleEnded,
    InvalidTicketPrice
} from "../src/RaffleHouse.sol";

event TicketPurchased(uint256 indexed raffleId, address indexed buyer, uint256 ticketId);

event WinnerChosen(uint256 indexed raffleId, uint256 winningTicketIndex);

event PrizeClaimed(uint256 indexed raffleId, address indexed winner, uint256 prizeAmount);

event RaffleCreated(
    uint256 indexed raffleId,
    uint256 ticketPrice,
    uint256 raffleStart,
    uint256 raffleEnd,
    string raffleName,
    string raffleSymbol
);

contract RaffleSystemTest is Test {
    uint256 public constant TICKET_PRICE = 0.1 ether;
    uint256 public constant MIN_DURATION = 1 hours;

    RaffleHouse public raffleHouse;
    address public owner;
    address public user1;
    address public user2;
    address public user3;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");
        user3 = makeAddr("user3");

        vm.deal(owner, 100 ether);
        vm.deal(user1, 100 ether);
        vm.deal(user2, 100 ether);
        vm.deal(user3, 100 ether);

        vm.prank(owner);
        raffleHouse = new RaffleHouse();
    }

    /// Test Contract State and Initialization
    function test_InitialState() public view {
        assertEq(raffleHouse.getRaffleCount(), 0, "Initial raffle count should be 0");
    }

    /// Test Raffle Creation
    function test_CreateRaffle() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;

        vm.expectEmit(true, false, false, true);
        emit RaffleCreated(0, TICKET_PRICE, startTime, endTime, "Test Raffle", "TRAF");

        vm.prank(owner);
        raffleHouse.createRaffle(TICKET_PRICE, startTime, endTime, "Test Raffle", "TRAF");

        RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(0);
        assertEq(raffle.ticketPrice, TICKET_PRICE);
        assertEq(raffle.raffleStart, startTime);
        assertEq(raffle.raffleEnd, endTime);
    }

    /// Test Invalid Raffle Creation
    function test_RevertWhen_CreateRaffleWithInvalidParams() public {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;

        // 1. Test zero ticket price
        vm.prank(owner);
        vm.expectRevert(TicketPriceTooLow.selector);
        raffleHouse.createRaffle(0, startTime, endTime, "Test", "TEST");

        // 2. Test past start time
        vm.prank(owner);
        vm.expectRevert(RaffleAlreadyStarted.selector);
        raffleHouse.createRaffle(TICKET_PRICE, block.timestamp - 1, endTime, "Test", "TEST");

        // 3. Test end time before start time
        vm.prank(owner);
        vm.expectRevert(InvalidRaffleEndTime.selector);
        raffleHouse.createRaffle(TICKET_PRICE, startTime, startTime - 1, "Test", "TEST");

        // 4. Test insufficient duration
        vm.prank(owner);
        vm.expectRevert(InsufficientRaffleDuration.selector);
        raffleHouse.createRaffle(TICKET_PRICE, startTime, startTime + MIN_DURATION - 1, "Test", "TEST");
    }

    /// Test Ticket Purchase
    function test_BuyTicket() public {
        uint256 raffleId = _createDefaultRaffle();

        // 1. Warp to raffle start time
        RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(raffleId);
        vm.warp(raffle.raffleStart);

        // 2. Buy ticket
        vm.prank(user1);
        vm.expectEmit(true, true, false, true);
        emit TicketPurchased(raffleId, user1, 0);
        raffleHouse.buyTicket{value: TICKET_PRICE}(raffleId);

        // 3. Verify ticket ownership
        TicketNFT ticketContract = raffle.ticketsContract;
        assertEq(ticketContract.ownerOf(0), user1);
    }

    /// Test Invalid Ticket Purchase
    function test_RevertWhen_InvalidTicketPurchase() public {
        uint256 raffleId = _createDefaultRaffle();
        RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(raffleId);

        // 1. Try to buy before start
        vm.prank(user1);
        vm.expectRevert(RaffleNotStarted.selector);
        raffleHouse.buyTicket{value: TICKET_PRICE}(raffleId);

        // 2. Warp to after end time
        vm.warp(raffle.raffleEnd + 1);
        vm.prank(user1);
        vm.expectRevert(RaffleEnded.selector);
        raffleHouse.buyTicket{value: TICKET_PRICE}(raffleId);

        // 3. Try with wrong price
        vm.warp(raffle.raffleStart);
        vm.prank(user1);
        vm.expectRevert(InvalidTicketPrice.selector);
        raffleHouse.buyTicket{value: TICKET_PRICE - 0.01 ether}(raffleId);
    }

    /// Test Winner Selection
    function test_ChooseWinner() public {
        uint256 raffleId = _createDefaultRaffle();
        RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(raffleId);

        // Buy some tickets
        vm.warp(raffle.raffleStart);
        vm.prank(user1);
        raffleHouse.buyTicket{value: TICKET_PRICE}(raffleId);
        vm.prank(user2);
        raffleHouse.buyTicket{value: TICKET_PRICE}(raffleId);

        // 2. Warp to end time
        vm.warp(raffle.raffleEnd + 1);

        vm.expectEmit(true, false, false, false);
        emit WinnerChosen(raffleId, 0);
        raffleHouse.chooseWinner(raffleId);

        raffle = raffleHouse.getRaffle(raffleId);
        assertTrue(raffle.winningTicketIndex < raffle.ticketsContract.totalSupply());
    }

    /// Test Prize Claiming
    function test_ClaimPrize() public {
        uint256 raffleId = _createDefaultRaffle();
        RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(raffleId);

        // 1. Buy tickets
        vm.warp(raffle.raffleStart);
        vm.prank(user1);
        raffleHouse.buyTicket{value: TICKET_PRICE}(raffleId);

        // 2. End raffle and choose winner
        vm.warp(raffle.raffleEnd + 1);
        raffleHouse.chooseWinner(raffleId);

        raffle = raffleHouse.getRaffle(raffleId);
        address winner = raffle.ticketsContract.ownerOf(raffle.winningTicketIndex);

        uint256 winnerBalanceBefore = winner.balance;

        // 3. Approve NFT transfer
        vm.prank(winner);
        raffle.ticketsContract.approve(address(raffleHouse), raffle.winningTicketIndex);

        // 4. Claim prize
        vm.prank(winner);
        raffleHouse.claimPrize(raffleId);

        assertEq(winner.balance - winnerBalanceBefore, TICKET_PRICE);
    }

    /* ============================================================================================== */
    /*                                           FUZZ TESTS                                           */
    /* ============================================================================================== */

    /// Fuzz test for raffle creation
    function testFuzz_CreateRaffle(uint256 _ticketPrice, uint256 _startDelay, uint256 _duration) public {
        // Bound the fuzz inputs to reasonable values
        _ticketPrice = bound(_ticketPrice, 0.001 ether, 100 ether);
        _startDelay = bound(_startDelay, 1 hours, 30 days);
        _duration = bound(_duration, MIN_DURATION, 365 days);

        uint256 startTime = block.timestamp + _startDelay;
        uint256 endTime = startTime + _duration;

        vm.prank(owner);
        raffleHouse.createRaffle(_ticketPrice, startTime, endTime, "Fuzz Raffle", "FUZZ");

        RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(raffleHouse.getRaffleCount() - 1);
        assertEq(raffle.ticketPrice, _ticketPrice);
        assertEq(raffle.raffleStart, startTime);
        assertEq(raffle.raffleEnd, endTime);
    }

    /// Fuzz test for buying multiple tickets
    function testFuzz_BuyMultipleTickets(uint8 _numTickets) public {
        // Bound number of tickets to prevent excessive gas usage
        _numTickets = uint8(bound(_numTickets, 1, 50));

        uint256 raffleId = _createDefaultRaffle();
        RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(raffleId);

        vm.warp(raffle.raffleStart);

        for (uint8 i = 0; i < _numTickets; i++) {
            vm.prank(user1);
            raffleHouse.buyTicket{value: TICKET_PRICE}(raffleId);
        }

        assertEq(raffle.ticketsContract.balanceOf(user1), _numTickets);
    }

    /// Fuzz test for multiple raffles and tickets
    function testFuzz_MultipleRafflesAndTickets(uint8 _numRaffles, uint8 _ticketsPerRaffle) public {
        // Bound inputs to prevent excessive gas usage
        _numRaffles = uint8(bound(_numRaffles, 1, 10));
        _ticketsPerRaffle = uint8(bound(_ticketsPerRaffle, 1, 20));

        for (uint8 i = 0; i < _numRaffles; i++) {
            uint256 raffleId = _createDefaultRaffle();
            RaffleHouse.Raffle memory raffle = raffleHouse.getRaffle(raffleId);

            vm.warp(raffle.raffleStart);

            for (uint8 j = 0; j < _ticketsPerRaffle; j++) {
                vm.prank(user1);
                raffleHouse.buyTicket{value: TICKET_PRICE}(raffleId);
            }

            vm.warp(raffle.raffleEnd + 1);
            raffleHouse.chooseWinner(raffleId);
        }

        assertEq(raffleHouse.getRaffleCount(), _numRaffles);
    }

    /* ============================================================================================== */
    /*                                        HELPER FUNCTIONS                                        */
    /* ============================================================================================== */

    /// Helper function to create a raffle
    function _createDefaultRaffle() private returns (uint256) {
        uint256 startTime = block.timestamp + 1 hours;
        uint256 endTime = startTime + 2 hours;

        vm.prank(owner);
        raffleHouse.createRaffle(TICKET_PRICE, startTime, endTime, "Test Raffle", "TRAF");
        return raffleHouse.getRaffleCount() - 1;
    }
}