// SPDX-License-Identifier: MIT

pragma solidity 0.8.4;

import "./ERC3754.sol";
import "@chainlink/contracts/src/v0.6/VRFConsumerBase.sol";

/**
 * THIS IS AN EXAMPLE CONTRACT WHICH USES HARDCODED VALUES FOR CLARITY.
 * PLEASE DO NOT USE THIS CODE IN PRODUCTION.
 */
contract RandomNumberConsumer is VRFConsumerBase {

    bytes32 internal keyHash;
    uint256 internal fee;

    uint256 public randomResult;

    /**
     * Constructor inherits VRFConsumerBase
     *
     * Network: Kovan
     * Chainlink VRF Coordinator address: 0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9
     * LINK token address:                0xa36085F69e2889c224210F603D836748e7dC0088
     * LINK membership address (made up): 0x60aE616a2155Ee3d9A68541Ba5644862310933d4
     * Key Hash: 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4
     */
    constructor()
        VRFConsumerBase(
            0xdD3782915140c8f3b190B5D67eAc6dc5760C46E9, // VRF Coordinator
            0xa36085F69e2889c224210F603D836748e7dC0088,  // LINK Token
            0x60aE616a2155Ee3d9A68541Ba5644862310933d4  // LINKMEMBER
        )
    {
        keyHash = 0x6c3699283bda56ad74f6b855546325b68d482e983852a7a82979cc4807b641f4;
        fee = 0.1 * 10 ** 18; // 0.1 LINK (Varies by network)
    }

    /**
     * Requests randomness
     */
    function getRandomNumber() public returns (bytes32 requestId) {
        require(LINK.balanceOf(address(this)) >= fee ||
                LINKMEMBER.isMember(_msgSender()), "Not enough LINK or not a member");
        if (LINKMEMBER.isMember(_msgSender())) {
            return requestRandomness(keyHash);
        } else {
            return requestRandomness(keyHash, fee);
        }
    }

    /**
     * Callback function used by VRF Coordinator
     */
    function fulfillRandomness(bytes32 requestId, uint256 randomness) internal override {
        randomResult = randomness;
    }

    // function withdrawLink() external {} - Implement a withdraw function to avoid locking your LINK in the contract
}

contract OracleMembership is ERC3754 {
    constructor() ERC3754("OracleMembership Token", "OMT") {}

    mapping(uint256 => uint256) public _membershipPrice;

    modifier onlyTokenOwner(uint256 tokenId) {
        require(ownerOf(tokenId) == _msgSender(), "Must be called by token owner");
        _;
    }

    function mint(address to, uint256 tokenId) external {
        _mint(to, tokenId);
        _approve(address(this), tokenId);
    }

    function isMember(address account) public view returns (bool) {
        return _holderTokens[account].length() > 0;
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
