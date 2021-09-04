// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC3754.sol";

contract TradeableRight is ERC3754 {
    constructor() ERC3754("TradeableRight Token", "TRT") {}

    mapping(uint256 => uint256) public _ownershipPrice;

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "Must be called by token owner");
        _;
    }

    function mint(address to, uint256 tokenId) {
        _mint(to, tokenId);
        _approve(address(this), tokenId);
    }

    function execute(uint256 tokenId, address target, bytes memory data) public onlyTokenOwner(tokenId) {
        (bool success, ) = target.call{value: 0}(data);
        require(success, "Not successful");
    }

    function setOwnershipPrice(uint256 tokenId, uint256 value) public onlyTokenOwner(tokenId) {
        require(value > 0, "Price must be greater than 0");
        _ownershipPrice[tokenId] = value;
    }

    function transferOwnership(uint256 tokenId) public payable {
        require(_ownershipPrice[tokenId] > 0, "Price not set");
        require(msg.value >= _ownershipPrice[tokenId], "Not enough");
        address owner = ownerOf(tokenId);
        transferFrom(owner, _msgSender(), tokenId);
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Not successful");
        _ownershipPrice[tokenId] = 0;
    }

    function _msgSender() private view returns (address) {
        return msg.sender;
    }
}
