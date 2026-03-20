// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import { DataTypes } from "../libraries/DataTypes.sol";

interface IIdentityToken is IERC721, IERC721Metadata {
    // -------------------------------------------------------------------------
    // Attribute management
    // -------------------------------------------------------------------------

    function setAttribute(uint256 tokenId, string calldata key, bytes calldata value) external;
    function deleteAttribute(uint256 tokenId, string calldata key) external;

    function getAttribute(uint256 tokenId, string calldata key) external view returns (bytes memory);

    function setAttributesBatch(uint256 tokenId, string[] calldata keys, bytes[] calldata values) external;

    function setName(uint256 tokenId, string calldata name) external;

    function setGithub(uint256 tokenId, string calldata github) external;

    // -------------------------------------------------------------------------
    // Endorsements
    // -------------------------------------------------------------------------

    function endorse(uint256 fromTokenId, uint256 toTokenId, bytes32 connectionType, uint256 validUntil) external;

    // -------------------------------------------------------------------------
    // View helpers
    // -------------------------------------------------------------------------

    function ownerToTokenId(address owner) external view returns (uint256);

    function identityStates(
        uint256 tokenId
    )
        external
        view
        returns (
            bool isCompromised,
            address backupWallet,
            address pendingBackupWallet,
            uint256 backupUnlockTime,
            uint256 validUntil
        );

    function attributes(uint256 tokenId, bytes32 keyHash) external view returns (bytes memory);

    function endorsements(
        uint256 tokenId,
        uint256 index
    )
        external
        view
        returns (
            uint256 endorserTokenId,
            bytes32 connectionType,
            uint256 timestamp,
            uint256 validUntil,
            uint256 revokedAt
        );

    // Identity helpers

    function hasIdentity(address owner) external view returns (bool);

    function getIdentity(uint256 tokenId) external view returns (DataTypes.Identity memory);

    function getIdentityByOwner(address owner) external view returns (uint256[] memory);

    function isVerified(uint256 tokenId) external view returns (bool);

    function isExpired(uint256 tokenId) external view returns (bool);
}
