// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IIdentityToken {
    function mint() external returns (uint256);

    function setAttribute(uint256 tokenId, string calldata key, bytes calldata value) external;

    function endorse(uint256 fromTokenId, uint256 toTokenId, bytes32 connectionType, uint256 validUntil) external;

    function ownerOf(uint256 tokenId) external view returns (address);

    function balanceOf(address owner) external view returns (uint256);

    function name() external view returns (string memory);

    function symbol() external view returns (string memory);

    function tokenURI(uint256 tokenId) external view returns (string memory);

    function supportsInterface(bytes4 interfaceId) external view returns (bool);

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
