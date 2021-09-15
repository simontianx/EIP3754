// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "./ERC3754.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

interface IERC721 {
    function mint(address to) external;
    function balanceOf(address owner) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

contract NFTOption is ERC3754, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _optionId;

    event TransferOption(address indexed from, address indexed to, uint256 optionId);

    // The initial price of option
    IERC721 private immutable _nft;
    uint256 private immutable _presaleEndingTime;
    uint256 private immutable _presaleStartingTime;
    uint256 private _initialOptionPrice;
    bool private _presaleOverStatus;

    struct OptionInfo {
        uint256 _optionPrice;
        uint256 _creationTime;
        uint256 _expiry;
        address _owner;
    }

    mapping(uint256 => OptionInfo) _optionInfo;

    constructor(address addr) ERC3754("Option Token", "OT") {
        _nft = IERC721(addr);
        _presaleStartingTime = block.timestamp;
        _presaleOverStatus = false;
        _presaleEndingTime = block.timestamp + 30 days;
        _optionId.increment();
    }

    modifier onlyOptionOwner(uint256 optionId) {
        require(ownerOf(optionId) == _msgSender(), "Only option owner");
        _;
    }

    // @notice People purchase right token from this function.
    // Once people purchase it, this function will mint right token for caller
    function buyOption() public payable returns (uint256 optionId) {
        require(!_isPresaleOver(), "Presale is over");
        require(_initialOptionPrice > 0, "Initial option price not set");
        require(msg.value >= _initialOptionPrice, "Not enough");

        optionId = _getOptionId();
        _mint(_msgSender(), optionId);
        _updateInfo(_msgSender(), optionId, true);
        _optionIdIncrement();

        emit TransferOption(address(0), _msgSender(), optionId);
    }

    // @notice Member can mint an NFT with an option
    function exerciseOption(uint256 optionId) public onlyOptionOwner(optionId) {
        if (_isExpired(optionId)) {
            _burnOption(optionId);
            return;
        }

        _nft.mint(_msgSender());
        _burnOption(optionId);
    }

    // @notice People can call this function to transfer their right token to someone's address
    function transferOption(uint256 optionId) public payable onlyOptionOwner(optionId) {
        require(!_isPresaleOver(), "Presale is over");
        require(_optionInfo[optionId]._optionPrice > 0, "price not set");
        require(msg.value >= _optionInfo[optionId]._optionPrice, "Not enough");

        if (_isExpired(optionId)) {
            _burnOption(optionId);
            return;
        }

        address owner = ownerOf(optionId);
        this.transferFrom(owner, _msgSender(), optionId);
        (bool success, ) = owner.call{value: msg.value}("");
        require(success, "Transfer not successful");
        _updateInfo(_msgSender(), optionId, false);
        emit TransferOption(owner, _msgSender(), optionId);
    }

    // @notice For sell the memberShip to others, the owner of token can set their token price
    function setOptionPrice(uint256 optionId, uint256 amount) public onlyOptionOwner(optionId) {
        require(amount > 0, "Price must be greater than 0");
        _optionInfo[optionId]._optionPrice = amount;
    }

    // @notice Owner can set the price of right token
    function setInitialOptionPrice(uint256 amount) public onlyOwner {
        _initialOptionPrice = amount;
    }

    // @notice Judge if token is expired
    function _isExpired(uint256 optionId) private view returns (bool) {
        require(_exists(optionId), "Option is non-existent");
        return _optionInfo[optionId]._expiry <= block.timestamp;
    }

    // @notice Judge if presale is over
    function _isPresaleOver() private view returns (bool) {
        return _presaleEndingTime <= block.timestamp || _presaleOverStatus;
    }

    // @notice If token is expired, call this function to burn it;
    function _burnOption(uint256 optionId) private {
        delete _optionInfo[optionId];
        _burn(optionId);
    }

    // @notice Reset some attribute of right token
    // For exmple, exchange the ownerShip of right token,
    // reset the price of right token
    // reset the time of minting
    // reset the expiration time
    function _updateInfo(address newOwner, uint256 optionId, bool init) private {
        _optionInfo[optionId]._owner = newOwner;
        _optionInfo[optionId]._optionPrice = 0;
        if (init) {
            _optionInfo[optionId]._creationTime = block.timestamp;
            _optionInfo[optionId]._expiry = block.timestamp + 7 days;
        }
    }

    function _getOptionId() private view returns (uint256) {
        return _optionId.current();
    }

    function _optionIdIncrement() private {
        _optionId.increment();
    }

}

contract TestNFT is ERC721, Ownable {
    using Counters for Counters.Counter;
    Counters.Counter private _tokenId;

    constructor() ERC721("TestNFT", "TT") {}

    function mint(address to) public {
        _mint(to, _getTokenId());
        _tokenIdIncrement();
    }

    function totalSupply() public view returns (uint256) {
        return _getTokenId();
    }

    function _getTokenId() private view returns (uint256) {
        return _tokenId.current();
    }

    function _tokenIdIncrement() private {
        _tokenId.increment();
    }
}
