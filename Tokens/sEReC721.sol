// SPDX-License-Identifier: GPL-3.0-or-later

pragma solidity ^0.8.4;

abstract contract sEReC721 {

    event Transfer(address indexed from, address indexed to, uint256 indexed id);
    event Approval(address indexed owner, address indexed spender, uint256 indexed id);
    event ApprovalForAll(address indexed owner, address indexed operator, bool approved);

    string public name;
    string public symbol;
    address public dev;
    uint256 public totalSupply;
    string public baseURI;

    mapping(uint256 tokenId => address) public ownerOf;
    mapping(address owner => uint256) public balanceOf;
    mapping(uint256 => address) private _tokenApprovals;
    mapping(address => mapping(address => bool)) private _operatorApprovals;

    constructor(string memory _name, string memory _symbol, string memory _baseURI) {
        name = _name;
        symbol = _symbol;
        baseURI = _baseURI;
    }

    function supportsInterface(bytes4 interfaceId) public view virtual returns (bool) {
        return
            interfaceId == 0x01ffc9a7 ||
            interfaceId == 0x80ac58cd ||
            interfaceId == 0x780e9d63 ||
            interfaceId == 0x5b5e139f;
    }

    function _mint(address to, uint256 tokenId) internal {
        require(to != address(0), "ERC721: mint to the zero address");
        require(ownerOf[tokenId] == address(0), "ERC721: token already minted");
        require(tokenId > 0, "ERC721: invalid tokenId");
        ownerOf[tokenId] = to;
        balanceOf[to]++;
        totalSupply++;
        emit Transfer(address(0), to, tokenId);
    }

    function approve(address to, uint256 tokenId) public virtual {
        address owner = ownerOf[tokenId];
        if (to == owner) revert();
        if (msg.sender != owner && !isApprovedForAll(owner, msg.sender)) revert();
        _tokenApprovals[tokenId] = to;
        emit Approval(owner, to, tokenId);
    }

    function getApproved(uint256 tokenId) public view virtual returns (address) {
        if (ownerOf[tokenId] == address(0)) revert();
        return _tokenApprovals[tokenId];
    }

    function setApprovalForAll(address operator, bool approved) public virtual {
        if (operator == msg.sender) revert();
        _operatorApprovals[msg.sender][operator] = approved;
        emit ApprovalForAll(msg.sender, operator, approved);
    }

    function isApprovedForAll(address owner, address operator) public view virtual returns (bool) {
        return _operatorApprovals[owner][operator];
    }

    function transferFrom(address from, address to, uint256 tokenId) public virtual {
        require(ownerOf[tokenId] == from, "ERC721: transfer of token that is not owned");
        require(to != address(0), "ERC721: transfer to the zero address");
        bool isApprovedOrOwner = (msg.sender == from ||
            msg.sender == getApproved(tokenId) ||
            isApprovedForAll(from, msg.sender));
        require(isApprovedOrOwner, "ERC721: transfer caller is not owner nor approved");
        delete _tokenApprovals[tokenId];
        ownerOf[tokenId] = to;
        balanceOf[from]--;
        balanceOf[to]++;
        emit Transfer(from, to, tokenId);
    }

    function safeTransferFrom(address from, address to, uint256 tokenId) public virtual {
        transferFrom(from, to, tokenId); // UNSAFE BITCH 🖕
    }

    function tokenURI(uint256 tokenId) public view virtual returns (string memory) {
        if (bytes(baseURI).length == 0) {return "";}
        return string(abi.encodePacked(baseURI, toString(tokenId)));
    }

    function toString(uint256 value) internal pure returns (string memory) {
        if (value == 0) {return "0";}
        uint256 temp = value; uint256 digits;
        while (temp != 0) {digits++; temp /= 10;}
        bytes memory buffer = new bytes(digits);
        while (value != 0) {digits -= 1; buffer[digits] = bytes1(uint8(value % 10) + 48); value /= 10;}
        return string(buffer);
    }
}
