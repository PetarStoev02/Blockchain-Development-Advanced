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
import {Test, console2} from "forge-std/Test.sol";
import {TicketNFT} from "../src/TicketNFT.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {IERC721Enumerable} from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";

contract TicketNFTTest is Test {
    TicketNFT public ticketNFT;
    address public owner;
    address public user1;
    address public user2;

    function setUp() public {
        owner = makeAddr("owner");
        user1 = makeAddr("user1");
        user2 = makeAddr("user2");

        vm.prank(owner);
        ticketNFT = new TicketNFT("Test Tickets", "TEST");
    }

    /// Test compliance
    function test_SupportsInterface() public view {
        assertTrue(ticketNFT.supportsInterface(type(IERC721).interfaceId));
        assertTrue(ticketNFT.supportsInterface(type(IERC721Enumerable).interfaceId));
    }

    /// Test initialization
    function test_Initialization() public view {
        assertEq(ticketNFT.name(), "Test Tickets");
        assertEq(ticketNFT.symbol(), "TEST");
        assertEq(ticketNFT.owner(), owner);
    }

    /// Test minting
    function test_SafeMint() public {
        vm.prank(owner);
        uint256 tokenId = ticketNFT.safeMint(user1);

        assertEq(ticketNFT.ownerOf(tokenId), user1);
        assertEq(ticketNFT.balanceOf(user1), 1);
        assertEq(ticketNFT.totalSupply(), 1);
    }

    /// Test minting permissions
    function test_RevertWhen_NonOwnerMints() public {
        vm.prank(user1);
        vm.expectRevert(abi.encodeWithSignature("OwnableUnauthorizedAccount(address)", user1));
        ticketNFT.safeMint(user2);
    }

    /// Test transfers
    function test_Transfer() public {
        vm.prank(owner);
        uint256 tokenId = ticketNFT.safeMint(user1);

        vm.prank(user1);
        ticketNFT.transferFrom(user1, user2, tokenId);

        assertEq(ticketNFT.ownerOf(tokenId), user2);
        assertEq(ticketNFT.balanceOf(user1), 0);
        assertEq(ticketNFT.balanceOf(user2), 1);
    }

    /// Test enumeration functionality
    function test_Enumeration() public {
        // 1. Mint multiple tokens
        uint256[] memory tokenIds = new uint256[](3);
        for (uint256 i = 0; i < 3; i++) {
            vm.prank(owner);
            tokenIds[i] = ticketNFT.safeMint(user1);
        }

        // 2. Test totalSupply
        assertEq(ticketNFT.totalSupply(), 3);

        // 3. Test tokenOfOwnerByIndex
        for (uint256 i = 0; i < 3; i++) {
            assertEq(ticketNFT.tokenOfOwnerByIndex(user1, i), tokenIds[i]);
        }

        // 4. Test tokenByIndex
        for (uint256 i = 0; i < 3; i++) {
            assertEq(ticketNFT.tokenByIndex(i), tokenIds[i]);
        }
    }

    /// Test ownership transfer
    function test_OwnershipTransfer() public {
        // 1. Transfer ownership
        vm.prank(owner);
        ticketNFT.transferOwnership(user1);

        // 2. Ownership not transferred yet (two-step process)
        assertEq(ticketNFT.owner(), owner);

        // 3. Accept ownership
        vm.prank(user1);
        ticketNFT.acceptOwnership();

        assertEq(ticketNFT.owner(), user1);
    }

    /* ============================================================================================== */
    /*                                           FUZZ TESTS                                           */
    /* ============================================================================================== */

    /// Fuzz test for minting multiple tokens
    function testFuzz_MultipleMints(uint8 _numMints) public {
        _numMints = uint8(bound(_numMints, 1, 100));

        uint256[] memory tokenIds = new uint256[](_numMints);

        for (uint8 i = 0; i < _numMints; i++) {
            vm.prank(owner);
            tokenIds[i] = ticketNFT.safeMint(user1);

            assertEq(ticketNFT.ownerOf(tokenIds[i]), user1);
            assertEq(ticketNFT.tokenOfOwnerByIndex(user1, i), tokenIds[i]);
            assertEq(ticketNFT.tokenByIndex(i), tokenIds[i]);
        }

        assertEq(ticketNFT.totalSupply(), _numMints);
        assertEq(ticketNFT.balanceOf(user1), _numMints);
    }
}