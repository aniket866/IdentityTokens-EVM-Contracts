// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { IERC165 } from "@openzeppelin/contracts/utils/introspection/IERC165.sol";
import { DataTypes } from "./libraries/DataTypes.sol";
import { Errors } from "./libraries/Errors.sol";
import { Events } from "./libraries/Events.sol";
import { IIdentityToken } from "./interfaces/IIdentityToken.sol";

contract IdentityToken is ERC721, IIdentityToken {
    error NonTransferable();

    uint256 private _nextTokenId = 1;

    // wallet => tokenId (enforce one identity per wallet)
    mapping(address => uint256) public ownerToTokenId;

    // tokenId => IdentityState
    mapping(uint256 => DataTypes.IdentityState) public identityStates;

    // tokenId => attribute keyHash => attribute value
    mapping(uint256 => mapping(bytes32 => bytes)) public attributes;

    // tokenId => array of Endorsements
    mapping(uint256 => DataTypes.Endorsement[]) public endorsements;

    modifier onlyTokenOwner(uint256 tokenId) {
        if (ownerOf(tokenId) != msg.sender) revert Errors.NotTokenOwner();
        _;
    }

    modifier notCompromised(uint256 tokenId) {
        if (identityStates[tokenId].isCompromised) revert Errors.IdentityCompromised();
        _;
    }

    constructor() ERC721("IdentityToken", "IDT") {}

    function supportsInterface(bytes4 interfaceId) public view override(ERC721, IERC165) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    function _update(address to, uint256 tokenId, address auth) internal override returns (address) {
        address from = _ownerOf(tokenId);

        // prevent transfers (only mint or burn allowed)
        if (from != address(0) && to != address(0)) revert NonTransferable();

        address prevOwner = super._update(to, tokenId, auth);

        // maintain ownerToTokenId mapping
        if (from != address(0)) {
            delete ownerToTokenId[from];
        }

        if (to != address(0)) {
            ownerToTokenId[to] = tokenId;
        }

        return prevOwner;
    }

    /**
     * @dev Mints a new self-issued identity token to the caller.
     */
    function mint() external returns (uint256) {
        if (balanceOf(msg.sender) != 0) revert Errors.AlreadyHasIdentity();

        uint256 tokenId = _nextTokenId++;

        _mint(msg.sender, tokenId);

        ownerToTokenId[msg.sender] = tokenId;

        return tokenId;
    }

    /**
     * @dev Sets a metadata attribute (e.g., name, social link) for an identity.
     */
    function setAttribute(
        uint256 tokenId,
        string calldata key,
        bytes calldata value
    ) external onlyTokenOwner(tokenId) notCompromised(tokenId) {
        _setAttribute(tokenId, key, value);
    }

    /**
     * @dev Returns the raw bytes value for a given string key on a token.
     *      Convenience wrapper: callers supply the human-readable key string
     *      instead of computing keccak256 manually.
     */
    function getAttribute(uint256 tokenId, string calldata key) external view returns (bytes memory) {
        return attributes[tokenId][keccak256(abi.encodePacked(key))];
    }

    /**
     * @dev Sets multiple attributes in a single transaction.
     *      keys and values must have equal length.
     *      Emits AttributeSet for every entry.
     */
    function setAttributesBatch(
        uint256 tokenId,
        string[] calldata keys,
        bytes[] calldata values
    ) external onlyTokenOwner(tokenId) notCompromised(tokenId) {
        if (keys.length != values.length) revert Errors.ArrayLengthMismatch();

        for (uint256 i = 0; i < keys.length; i++) {
            _setAttribute(tokenId, keys[i], values[i]);
        }
    }

    /**
     * @dev Convenience setter for the "name" attribute.
     */
    function setName(uint256 tokenId, string calldata name) external onlyTokenOwner(tokenId) notCompromised(tokenId) {
        _setAttribute(tokenId, "name", bytes(name));
    }

    /**
     * @dev Convenience setter for the "github" attribute.
     */
    function setGithub(
        uint256 tokenId,
        string calldata github
    ) external onlyTokenOwner(tokenId) notCompromised(tokenId) {
        _setAttribute(tokenId, "github", bytes(github));
    }

    /**
     * @notice Deletes an attribute for a given identity token.
     * @dev Hashes the provided key using keccak256 and removes the stored value.
     *      Emits {AttributeDeleted}. If the key does not exist, this is a no-op.
     */

    function deleteAttribute(
        uint256 tokenId,
        string calldata key
    ) external onlyTokenOwner(tokenId) notCompromised(tokenId) {
        bytes32 keyHash = keccak256(abi.encodePacked(key));

        delete attributes[tokenId][keyHash];

        emit Events.AttributeDeleted(tokenId, keyHash);
    }

    /**
     * @dev Allows an identity to endorse another identity.
     */
    function endorse(
        uint256 fromTokenId,
        uint256 toTokenId,
        bytes32 connectionType,
        uint256 validUntil
    ) external onlyTokenOwner(fromTokenId) notCompromised(fromTokenId) {
        if (fromTokenId == toTokenId) revert Errors.SelfEndorsement();
        if (_ownerOf(toTokenId) == address(0)) revert Errors.TargetInvalid();

        DataTypes.Endorsement[] storage list = endorsements[toTokenId];

        // prevent duplicate active endorsements
        for (uint256 i = 0; i < list.length; i++) {
            DataTypes.Endorsement storage e = list[i];

            bool active = e.revokedAt == 0 && (e.validUntil == 0 || e.validUntil >= block.timestamp);

            if (active && e.endorserTokenId == fromTokenId && e.connectionType == connectionType) {
                revert Errors.DuplicateEndorsement();
            }
        }

        DataTypes.Endorsement memory newEndorsement = DataTypes.Endorsement({
            endorserTokenId: fromTokenId,
            connectionType: connectionType,
            timestamp: block.timestamp,
            validUntil: validUntil,
            revokedAt: 0
        });

        endorsements[toTokenId].push(newEndorsement);

        emit Events.EndorsementGiven(fromTokenId, toTokenId, connectionType, validUntil);
    }

    // -------------------------------------------------------------------------
    // Internal
    // -------------------------------------------------------------------------

    /**
     * @dev Core write path shared by setAttribute, setAttributesBatch, and
     *      the typed helper setters. Hashes the key, stores the value, and
     *      emits AttributeSet with the original key string for off-chain indexing.
     */
    function _setAttribute(uint256 tokenId, string memory key, bytes memory value) internal {
        bytes32 keyHash = keccak256(abi.encodePacked(key));

        attributes[tokenId][keyHash] = value;

        emit Events.AttributeSet(tokenId, keyHash, key, value);
    }
}
