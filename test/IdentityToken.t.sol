// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { Test } from "forge-std/Test.sol";
import { IdentityToken } from "../src/IdentityToken.sol";
import { DataTypes } from "../src/libraries/DataTypes.sol";
import { Errors } from "../src/libraries/Errors.sol";
import { Schema } from "../src/libraries/Schema.sol";

contract IdentityTokenTest is Test {
    event AttributeSet(uint256 indexed tokenId, bytes32 indexed keyHash, string key, bytes value);

    IdentityToken public identityToken;
    address public alice = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        identityToken = new IdentityToken();
    }

    // -------------------------------------------------------------------------
    // Mint
    // -------------------------------------------------------------------------

    function test_Mint() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        assertEq(tokenId, 1);
        assertEq(identityToken.ownerOf(1), alice);
        assertEq(identityToken.balanceOf(alice), 1);
    }

    // -------------------------------------------------------------------------
    // setAttribute / getAttribute
    // -------------------------------------------------------------------------

    function test_SetAttribute() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(alice);
        identityToken.setAttribute(tokenId, "name", bytes("Alice Nakamoto"));

        bytes32 keyHash = keccak256(abi.encodePacked("name"));
        bytes memory retrievedValue = identityToken.attributes(tokenId, keyHash);

        assertEq(string(retrievedValue), "Alice Nakamoto");
    }

    function test_GetAttribute() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(alice);
        identityToken.setAttribute(tokenId, "name", bytes("Alice Nakamoto"));

        assertEq(string(identityToken.getAttribute(tokenId, "name")), "Alice Nakamoto");
    }

    function test_GetAttribute_MatchesRawMapping() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(alice);
        identityToken.setAttribute(tokenId, "github", bytes("https://github.com/alice"));

        assertEq(
            string(identityToken.getAttribute(tokenId, "github")),
            string(identityToken.attributes(tokenId, Schema.GITHUB))
        );
    }

    function test_SetAttribute_PhoneEmail_HashCompatibility() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        // Phone set/get via raw key and hashed Schema key consistency
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AttributeSet(tokenId, Schema.PHONE, "phone", bytes("1234567890"));
        identityToken.setAttribute(tokenId, "phone", bytes("1234567890"));

        assertEq(string(identityToken.getAttribute(tokenId, "phone")), "1234567890");
        assertEq(string(identityToken.attributes(tokenId, Schema.PHONE)), "1234567890");

        // Update phone value
        vm.prank(alice);
        identityToken.setAttribute(tokenId, "phone", bytes("0987654321"));

        assertEq(string(identityToken.getAttribute(tokenId, "phone")), "0987654321");
        assertEq(string(identityToken.attributes(tokenId, Schema.PHONE)), "0987654321");

        // Clear phone value
        vm.prank(alice);
        identityToken.setAttribute(tokenId, "phone", bytes(""));

        assertEq(identityToken.getAttribute(tokenId, "phone").length, 0);
        assertEq(identityToken.attributes(tokenId, Schema.PHONE).length, 0);

        // Email set/get via raw key and hashed Schema key consistency
        vm.prank(alice);
        vm.expectEmit(true, true, true, true);
        emit AttributeSet(tokenId, Schema.EMAIL, "email", bytes("alice@example.com"));
        identityToken.setAttribute(tokenId, "email", bytes("alice@example.com"));

        assertEq(string(identityToken.getAttribute(tokenId, "email")), "alice@example.com");
        assertEq(string(identityToken.attributes(tokenId, Schema.EMAIL)), "alice@example.com");

        // Update email value
        vm.prank(alice);
        identityToken.setAttribute(tokenId, "email", bytes("alice+alias@example.com"));

        assertEq(string(identityToken.getAttribute(tokenId, "email")), "alice+alias@example.com");
        assertEq(string(identityToken.attributes(tokenId, Schema.EMAIL)), "alice+alias@example.com");

        // Clear email value
        vm.prank(alice);
        identityToken.setAttribute(tokenId, "email", bytes(""));

        assertEq(identityToken.getAttribute(tokenId, "email").length, 0);
        assertEq(identityToken.attributes(tokenId, Schema.EMAIL).length, 0);
    }

    function test_SetAttribute_SocialLinks() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(alice);
        identityToken.setAttribute(tokenId, "github", bytes("https://github.com/alice"));
        vm.prank(alice);
        identityToken.setAttribute(tokenId, "linkedin", bytes("https://linkedin.com/in/alice"));
        vm.prank(alice);
        identityToken.setAttribute(tokenId, "twitter", bytes("https://twitter.com/alice"));

        assertEq(string(identityToken.getAttribute(tokenId, "github")), "https://github.com/alice");
        assertEq(string(identityToken.getAttribute(tokenId, "linkedin")), "https://linkedin.com/in/alice");
        assertEq(string(identityToken.getAttribute(tokenId, "twitter")), "https://twitter.com/alice");
    }

    function test_OverwriteAttribute() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(alice);
        identityToken.setAttribute(tokenId, "name", bytes("Alice"));
        vm.prank(alice);
        identityToken.setAttribute(tokenId, "name", bytes("Alice Nakamoto"));

        assertEq(string(identityToken.getAttribute(tokenId, "name")), "Alice Nakamoto");
    }

    function test_SetAttribute_EmptyValue() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(alice);
        identityToken.setAttribute(tokenId, "name", bytes(""));

        assertEq(identityToken.getAttribute(tokenId, "name").length, 0);
    }

    function test_SetAttribute_LongURL() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        string memory url = "https://www.linkedin.com/in/alice-nakamoto-very-long-profile-url-example-1234567890";
        vm.prank(alice);
        identityToken.setAttribute(tokenId, "linkedin", bytes(url));

        assertEq(string(identityToken.getAttribute(tokenId, "linkedin")), url);
    }

    // -------------------------------------------------------------------------
    // Typed helper setters
    // -------------------------------------------------------------------------

    function test_SetName() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(alice);
        identityToken.setName(tokenId, "Alice Nakamoto");

        assertEq(string(identityToken.attributes(tokenId, Schema.NAME)), "Alice Nakamoto");
    }

    function test_SetGithub() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(alice);
        identityToken.setGithub(tokenId, "https://github.com/alice");

        assertEq(string(identityToken.attributes(tokenId, Schema.GITHUB)), "https://github.com/alice");
    }

    // -------------------------------------------------------------------------
    // Batch setter
    // -------------------------------------------------------------------------

    function test_SetAttributesBatch() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        string[] memory keys = new string[](4);
        keys[0] = "name";
        keys[1] = "github";
        keys[2] = "nationality";
        keys[3] = "residence";

        bytes[] memory values = new bytes[](4);
        values[0] = bytes("Alice Nakamoto");
        values[1] = bytes("https://github.com/alice");
        values[2] = bytes("Japanese");
        values[3] = bytes("Tokyo");

        vm.prank(alice);
        identityToken.setAttributesBatch(tokenId, keys, values);

        assertEq(string(identityToken.getAttribute(tokenId, "name")), "Alice Nakamoto");
        assertEq(string(identityToken.getAttribute(tokenId, "github")), "https://github.com/alice");
        assertEq(string(identityToken.getAttribute(tokenId, "nationality")), "Japanese");
        assertEq(string(identityToken.getAttribute(tokenId, "residence")), "Tokyo");
    }

    function test_SetAttributesBatch_SingleEntry() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        string[] memory keys = new string[](1);
        keys[0] = "age";

        bytes[] memory values = new bytes[](1);
        values[0] = bytes("30");

        vm.prank(alice);
        identityToken.setAttributesBatch(tokenId, keys, values);

        assertEq(string(identityToken.getAttribute(tokenId, "age")), "30");
    }

    // -------------------------------------------------------------------------
    // Access control
    // -------------------------------------------------------------------------

    function test_RevertIf_NotOwnerSetsAttribute() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(bob);
        vm.expectRevert(Errors.NotTokenOwner.selector);
        identityToken.setAttribute(tokenId, "name", bytes("Hacker Bob"));
    }

    function test_RevertIf_NotOwnerBatchSetsAttribute() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        string[] memory keys = new string[](1);
        keys[0] = "name";
        bytes[] memory values = new bytes[](1);
        values[0] = bytes("Hacker Bob");

        vm.prank(bob);
        vm.expectRevert(Errors.NotTokenOwner.selector);
        identityToken.setAttributesBatch(tokenId, keys, values);
    }

    function test_RevertIf_NotOwnerUsesSetName() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        vm.prank(bob);
        vm.expectRevert(Errors.NotTokenOwner.selector);
        identityToken.setName(tokenId, "Hacker Bob");
    }

    function test_RevertIf_BatchLengthMismatch() public {
        vm.prank(alice);
        uint256 tokenId = identityToken.mint();

        string[] memory keys = new string[](2);
        keys[0] = "name";
        keys[1] = "github";
        bytes[] memory values = new bytes[](1);
        values[0] = bytes("Alice Nakamoto");

        vm.prank(alice);
        vm.expectRevert(Errors.ArrayLengthMismatch.selector);
        identityToken.setAttributesBatch(tokenId, keys, values);
    }

    // -------------------------------------------------------------------------
    // Schema constants
    // -------------------------------------------------------------------------

    function test_SchemaConstants() public pure {
        assertEq(Schema.NAME, keccak256(abi.encodePacked("name")));
        assertEq(Schema.AGE, keccak256(abi.encodePacked("age")));
        assertEq(Schema.NATIONALITY, keccak256(abi.encodePacked("nationality")));
        assertEq(Schema.RESIDENCE, keccak256(abi.encodePacked("residence")));
        assertEq(Schema.GITHUB, keccak256(abi.encodePacked("github")));
        assertEq(Schema.LINKEDIN, keccak256(abi.encodePacked("linkedin")));
        assertEq(Schema.TWITTER, keccak256(abi.encodePacked("twitter")));
        assertEq(Schema.PHONE, keccak256(abi.encodePacked("phone")));
        assertEq(Schema.EMAIL, keccak256(abi.encodePacked("email")));
    }

    // -------------------------------------------------------------------------
    // Endorsement (unchanged)
    // -------------------------------------------------------------------------

    function test_Endorse() public {
        vm.prank(alice);
        uint256 aliceId = identityToken.mint();

        vm.prank(bob);
        uint256 bobId = identityToken.mint();

        bytes32 connectionType = keccak256(abi.encodePacked("Colleague"));
        uint256 validUntil = block.timestamp + 365 days;

        vm.prank(alice);
        identityToken.endorse(aliceId, bobId, connectionType, validUntil);

        (
            uint256 endorserTokenId,
            bytes32 storedConnectionType,
            ,
            uint256 storedValidUntil,
            uint256 revokedAt
        ) = identityToken.endorsements(bobId, 0);

        assertEq(endorserTokenId, aliceId);
        assertEq(storedConnectionType, connectionType);
        assertEq(storedValidUntil, validUntil);
        assertEq(revokedAt, 0);
    }
}
