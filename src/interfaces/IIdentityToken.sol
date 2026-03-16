// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { IERC721 } from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import { IERC721Metadata } from "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";

interface IIdentityToken is IERC721, IERC721Metadata {
    function setAttribute(uint256 tokenId, string calldata key, bytes calldata value) external;

    function endorse(uint256 fromTokenId, uint256 toTokenId, bytes32 connectionType, uint256 validUntil) external;

    function revokeEndorsement(uint256 fromTokenId, uint256 toTokenId, uint256 index) external;

    function ownerToTokenId(address owner) external view returns (uint256);

    function identityStates(
        uint256 tokenId
    )
        external
        view
        returns (bool isCompromised, address backupWallet, address pendingBackupWallet, uint256 backupUnlockTime);

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
}
