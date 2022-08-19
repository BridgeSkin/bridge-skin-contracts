// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Royalty.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BridgeSkinCSGO is
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    ERC721Royalty,
    Pausable,
    Ownable
{
    using ECDSA for bytes32;
    using SafeMath for uint256;

    string public baseTokenURI = "ipfs://";
    mapping(uint256 => uint8) internal mintedTokens;
    address public signerAddress = 0x0000000000000000000000000000000000000000;

    event Mint(address indexed owner, uint256 indexed tokenID);
    event Withdraw(address indexed owner, uint256 indexed tokenID);

    constructor() ERC721("Bridge Skin CS:GO", "BSCS") {
        setDefaultRoyalty(msg.sender, 150);
        signerAddress = msg.sender;
    }

    function safeMint(
        uint256 tokenID,
        string memory uri,
        bytes memory sign
    ) public whenNotPaused {
        require(mintedTokens[tokenID] == 0, "TOKEN ALREADY MINTED");
        require(
            verifyMessage(append(Strings.toHexString(uint160(msg.sender), 20), uri, Strings.toString(tokenID)), sign) == true,
            "BAD SIGN"
        );

        mintedTokens[tokenID] = 1;

        _safeMint(msg.sender, tokenID);
        _setTokenURI(tokenID, uri);

        emit Mint(msg.sender, tokenID);
    }

    function withdraw(uint256 tokenID) public whenNotPaused {
        address tokenOwner = ownerOf(tokenID);
        require(msg.sender == tokenOwner, "YOU ARE NOT THE OWNER");

        require(mintedTokens[tokenID] == 1, "TOKEN ALREADY BURNED");

        mintedTokens[tokenID] = 2;
        _burn(tokenID);
        emit Withdraw(tokenOwner, tokenID);
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return baseTokenURI;
    }

    function setBaseURI(string memory _baseTokenURI) public onlyOwner {
        baseTokenURI = _baseTokenURI;
    }

    function mintedToken(uint256 tokenID) public view returns (uint8) {
        return mintedTokens[tokenID];
    }

    function setSignerAddress(address signer) public onlyOwner {
        signerAddress = signer;
    }

    function setDefaultRoyalty(address receiver, uint96 feeNumerator)
        public
        onlyOwner
    {
        _setDefaultRoyalty(receiver, feeNumerator);
    }

    function tokensOfOwner(address _owner)
        external
        view
        returns (uint256[] memory)
    {
        uint256 tokenCount = balanceOf(_owner);
        uint256[] memory tokensId = new uint256[](tokenCount);

        for (uint256 i = 0; i < tokenCount; i++) {
            tokensId[i] = tokenOfOwnerByIndex(_owner, i);
        }
        return tokensId;
    }

    function verifyMessage(string memory message, bytes memory sign)
        internal
        view
        returns (bool)
    {
        bytes memory s = bytes(message);
        bytes32 m = keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n",
                Strings.toString(s.length),
                s
            )
        );
        return signerAddress == m.recover(sign);
    }

    function append(string memory a, string memory b, string memory c)
        internal
        pure
        returns (string memory)
    {
        return string(abi.encodePacked(a, "/", b, "/", c));
    }

    function pause() public onlyOwner {
        _pause();
    }

    function unpause() public onlyOwner {
        _unpause();
    }

    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 tokenId
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage, ERC721Royalty)
    {
        super._burn(tokenId);
    }

    function tokenURI(uint256 tokenId)
        public
        view
        override(ERC721, ERC721URIStorage)
        returns (string memory)
    {
        return super.tokenURI(tokenId);
    }

    function supportsInterface(bytes4 interfaceId)
        public
        view
        override(ERC721, ERC721Enumerable, ERC721Royalty)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
