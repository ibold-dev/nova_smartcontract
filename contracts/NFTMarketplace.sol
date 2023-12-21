// SPDX-License-Identifier: Apache-2.0
pragma solidity ^0.8.4;

//INTERNAL IMPORT
import {ERC721URIStorage} from "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

//HARDHAT CONSOLE
import "hardhat/console.sol";

/**
 * @dev Defines NFTMarketplace contract
 * @notice NFTMarketplace is ERC721Storage
 */

contract NFTMarketplace is ERC721URIStorage, ReentrancyGuard {
    /**
     * @dev Defines state variables
     */

    uint256 private _nextTokenId;
    uint256 private _itemsSold;
    address payable owner;
    uint256 listingPrice = 0.0015 ether;

    /**
     * @dev Defines mapping for id to MarketItem.
     */

    mapping(uint256 => MarketItem) private idMarketItem;

    /**
     * @dev Defines struct for MarketItem.
     * @param tokenId Created ERC721 tokenId.
     * @param seller Address of ERC721 token seller.
     * @param owner Address of current ERC721 token owner.
     * @param price Price of ERC721 token.
     * @param sold If ERC721 is sold.
     */

    struct MarketItem {
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }

    /**
     * @dev Defines event for ERC721 token created
     * @param tokenId Created ERC721 tokenId.
     * @param seller Address of ERC721 token seller.
     * @param owner Address of current ERC721 token owner.
     * @param price Price of ERC721 token.
     * @param sold If ERC721 is sold.
     */

    event idMarketItemCreated(
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );

    /**
     * @dev Defines a modifer to ensure only contract creator calls function.
     */

    modifier onlyOwner() {
        require(
            msg.sender == owner,
            "You do not have permission to call function"
        );
        _;
    }

    /**
     * @dev Defines a constructor that sets contract deployer to owner.
     */

    constructor() ERC721("Nova NFT Marketplace", "NNM") {
        owner = payable(msg.sender);
    }

    /**
     * @dev Defines a function to update listing price.
     * @notice Sets listing price.
     * @param _listingPrice The listing price set by contract.
     */

    function updateListingPrice(
        uint256 _listingPrice
    ) public payable onlyOwner {
        listingPrice = _listingPrice;
    }

    /**
     * @dev defines a function to get listing price.
     * @notice Returns listing price.
     */

    function getListingPrice() public view returns (uint256) {
        return listingPrice;
    }

    /**
     * @dev Defines a function to create token.
     * @notice Returns a new tokenId.
     * @param tokenURI Token URI of created ERC721 token
     * @param price Price of ERC721 token
     */

    function createToken(
        string memory tokenURI,
        uint256 price
    ) public payable returns (uint256) {
        uint256 newTokenId = _nextTokenId++;
        _safeMint(msg.sender, newTokenId);
        _setTokenURI(newTokenId, tokenURI);
        createMarketItem(newTokenId, price);
        return newTokenId;
    }

    /**
     * @dev Defines a function to create marketplace item.
     * @notice Creates a new ERC721 token for marketplace.
     * @param tokenId created ERC721 tokenId.
     * @param price price of created ERC721 token.
     */

    function createMarketItem(uint256 tokenId, uint256 price) private {
        require(price > 0, "Price should be greater than 0");
        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );

        idMarketItem[tokenId] = MarketItem(
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );

        _safeTransfer(msg.sender, address(this), tokenId);

        emit idMarketItemCreated(
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );
    }

    /**
     * @dev Defines a function to resell ERC721 token.
     * @param tokenId ERC721 tokenId.
     * @param price New Erc721 token price.
     */

    function reSellToken(
        uint256 tokenId,
        uint256 price
    ) public payable nonReentrant {
        require(
            idMarketItem[tokenId].owner == msg.sender,
            "You don't own this NFT"
        );

        require(
            msg.value == listingPrice,
            "Price must be equal to listing price"
        );
        idMarketItem[tokenId].sold = false;
        idMarketItem[tokenId].price = price;
        idMarketItem[tokenId].seller = payable(msg.sender);
        idMarketItem[tokenId].owner = payable(address(this));

        _itemsSold--;
        _safeTransfer(msg.sender, address(this), tokenId);
    }

    /**
     * @dev Defines a function to create sale on marketplace.
     * @param tokenId ERC721 tokenId.
     */

    function createMarketSale(uint256 tokenId) public payable nonReentrant {
        uint256 price = idMarketItem[tokenId].price;

        require(
            msg.value == price,
            "Please submit the asking pricr in order to complete transaction"
        );

        idMarketItem[tokenId].owner = payable(msg.sender);
        idMarketItem[tokenId].sold = true;
        idMarketItem[tokenId].owner = payable(address(0));

        _itemsSold++;
        _safeTransfer(address(this), msg.sender, tokenId);

        payable(owner).transfer(listingPrice);
        payable(idMarketItem[tokenId].seller).transfer(msg.value);
    }

    /**
     * @dev Defines a function to fetch market item.
     */

    function fetchMarketItem() public view returns (MarketItem[] memory) {
        uint256 itemCount = _nextTokenId;
        uint256 unSoldItemCount = _nextTokenId - _itemsSold;
        uint256 currentIndex = 0;

        MarketItem[] memory items = new MarketItem[](unSoldItemCount);
        for (uint256 i = 0; i < itemCount; i++) {
            if (idMarketItem[i + 1].owner == address(this)) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /**
     * @dev Defines a function to fetch connected wallet NFT.
     */

    function fetchMyNFT() public view returns (MarketItem[] memory) {
        uint256 totalCount = _nextTokenId;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    /**
     * @dev Defines a function to fetch listed NFTs.
     */

    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalCount = _nextTokenId;
        uint256 itemCount = 0;
        uint256 currentIndex = 0;
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }
        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalCount; i++) {
            if (idMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }
}
