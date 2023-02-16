// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";

contract BridgeSkinCSGO is
    ERC721Enumerable,
    ERC721URIStorage,
    ERC721Burnable,
    Pausable,
    Ownable
{
    using ECDSA for bytes32;
    using SafeMath for uint256;
    using SafeERC20 for IERC20;

    string public baseTokenURI = "ipfs://";
    mapping(uint256 => uint8) internal mintedTokens;
    address public signer = 0x0000000000000000000000000000000000000000;
    uint256 public fee = 1000000000000000;

    event Mint(address indexed owner, uint256 indexed tokenID);
    event Withdraw(address indexed owner, uint256 indexed tokenID);
    event Migrate(address indexed owner, uint256 indexed tokenID);

    constructor() ERC721("Bridge Skin CS:GO", "BSCS") {
        signer = msg.sender;
    }

    function safeMint(
        uint256[] memory tokenID,
        string[] memory uri,
        string[] memory salt,
        bytes[] memory sign
    ) public whenNotPaused {
        uint256 length = tokenID.length;
        require(length == uri.length, "Invalid input");
        require(length == salt.length, "Invalid input");
        require(length == sign.length, "Invalid input");

        for (uint256 i = 0; i < length; i++) {
            require(mintedTokens[tokenID[i]] == 0, "Token already minted");
            require(
                verifyMessage(
                    msg.sender,
                    tokenID[i],
                    uri[i],
                    salt[i],
                    sign[i]
                ) == true,
                "Invalid signature"
            );

            mintedTokens[tokenID[i]] = 1;

            _safeMint(msg.sender, tokenID[i]);
            _setTokenURI(tokenID[i], uri[i]);

            emit Mint(msg.sender, tokenID[i]);
        }
    }

    function withdraw(uint256[] memory tokenID) public payable whenNotPaused {
        require(msg.value >= fee, "Insufficient to cover fees");

        for (uint256 i = 0; i < tokenID.length; i++) {
            address tokenOwner = ownerOf(tokenID[i]);
            require(msg.sender == tokenOwner, "You are not the owner");

            require(mintedTokens[tokenID[i]] == 1, "Token already burned");

            mintedTokens[tokenID[i]] = 2;
            _burn(tokenID[i]);
            emit Withdraw(tokenOwner, tokenID[i]);
        }
    }

    function migrate(uint256[] memory tokenID) public whenNotPaused {
        for (uint256 i = 0; i < tokenID.length; i++) {
            address tokenOwner = ownerOf(tokenID[i]);
            require(msg.sender == tokenOwner, "You are not the owner");

            require(mintedTokens[tokenID[i]] == 1, "Token already burned");

            mintedTokens[tokenID[i]] = 2;
            _burn(tokenID[i]);
            emit Migrate(tokenOwner, tokenID[i]);
        }
    }

    function withdrawBalance() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

    function withdrawToken(IERC20 token, address to, uint256 amount) external onlyOwner {
        token.safeTransfer(to, amount);
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

    function setSigner(address s) public onlyOwner {
        signer = s;
    }

    function setFee(uint256 i) public onlyOwner {
        fee = i;
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

    function verifyMessage(
        address addr,
        uint256 id,
        string memory uri,
        string memory salt,
        bytes memory sign
    ) internal view returns (bool) {
        return
            keccak256(abi.encodePacked(addr, id, uri, salt))
                .toEthSignedMessageHash()
                .recover(sign) == signer;
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
        uint256 tokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) whenNotPaused {
        super._beforeTokenTransfer(from, to, tokenId, batchSize);
    }

    function _burn(uint256 tokenId)
        internal
        override(ERC721, ERC721URIStorage)
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
        override(ERC721, ERC721Enumerable)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}