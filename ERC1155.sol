// SPDX-License-Identifier: MIT
pragma solidity >0.4.0<=0.9.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC1155/extensions/ERC1155Supply.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
 import "hardhat/console.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

// https://gateway.pinata.cloud/ipfs/QmUrGsnXcvQgJDSAFnsomjT9nQWdDPrbscu9x4Y48EEFkm/1.jpg
//25000000000000000
//20000000000000000
// 1000000000000000000
contract NFT_MarketPlace is ERC1155, Ownable,ReentrancyGuard {
   address payable public _owner;
    constructor() ERC1155("")
     {
        _owner = payable(msg.sender);
     }

      mapping(uint256 => mapping(address => uint256)) public _balances; 

    using Counters for Counters.Counter;
    string private _baseURI = "";
    mapping(uint256 => string) public _tokenURIs;
    mapping(uint256 => MarketItem) public idToMarketItem;


    Counters.Counter public _itemIds;
    Counters.Counter public _itemsSold; 
    Counters.Counter public _tokenIds;

    uint256 listingprice=0.025 ether;

    struct MarketItem {
       uint256 itemId;
        uint256 tokenId;
        address payable seller;
        address payable owner;
        uint256 price;
        bool sold;
    }
    event MarketItemCreated(
        uint256 indexed itemId,
        uint256 indexed tokenId,
        address seller,
        address owner,
        uint256 price,
        bool sold
    );
    event Transfer(address indexed sender,address indexed receiver,uint256 value);

    /** Return the listing price of contract */
     function getListingPrice() public view returns(uint256)
     {
         return listingprice;
      }
     /* Updates the listing price of the contract */
    function updateListingPrice(uint _listingPrice) public payable {
      require(_owner == msg.sender, "Only marketplace owner can update listing price.");
      listingprice = _listingPrice;
    }


    function mintToken(
        string memory tokenURI,
        uint256 amount,
        uint256 price
    ) public payable returns (uint256) {
         _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId, amount, "");
        _setTokenUri(newItemId, tokenURI);
        createMarketItem(newItemId, price, amount);
        return newItemId;
    }

    function mintBatch(
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) public onlyOwner {
        _mintBatch(to, ids, amounts, data);
    }

// create marketplace items
    function createMarketItem(
        uint256 tokenId,
        uint256 price,
        uint256 amount
    ) private  nonReentrant{
      _itemIds.increment();
         uint256 itemId=_itemIds.current();
        require(price > 0, "Price must be at least 1 wei");
        require(msg.value == listingprice, "Please provide correct listing price");
        idToMarketItem[itemId] = MarketItem(
           itemId,
            tokenId,
            payable(msg.sender),
            payable(address(this)),
            price,
            false
        );
        setApprovalForAll(address(this), true);

        transferFrom(msg.sender, address(this), tokenId, amount, "");

        emit MarketItemCreated(
          itemId,
            tokenId,
            msg.sender,
            address(this),
            price,
            false
        );     
    }
    
/* Returns all unsold market items */
    function fetchMarketItems() public view returns (MarketItem[] memory) {

    uint256 itemCount = _tokenIds.current();
    uint256 unsoldItemCount = _tokenIds.current() - _itemsSold.current();
    uint currentIndex=0;

    MarketItem[] memory items=new MarketItem[](unsoldItemCount);

    for(uint i=0;i<itemCount;i++)
    {
         if(idToMarketItem[i+1].owner==address(this))
         {
            uint currentId=i+1;
            MarketItem storage currentItem=idToMarketItem[currentId];
            items[currentIndex]=currentItem;
            currentIndex+=1;
        }
    }
    return items;

    }

/**Create the Sale of a marketplace item */
/**Transfer ownership of the item, as well as funds between partied */
function createMarketSale( uint256 itemId,uint256 amount) public payable  nonReentrant
{
        uint256 price = idToMarketItem[itemId].price;
    
      //  address owner = idToMarketItem[itemId].owner;
        address seller = idToMarketItem[itemId].seller;
        uint256 tokenId = idToMarketItem[itemId].tokenId;
        require(msg.value == price, "Please sumbit the asking price in order to complete the purchase");

        idToMarketItem[itemId].owner = payable(msg.sender);
        idToMarketItem[itemId].sold = true;
        idToMarketItem[itemId].seller=payable(address(0));
        _itemsSold.increment();
        _safeTransferFrom(address(this), msg.sender, tokenId, amount, "");
        payable(_owner).transfer(listingprice);
        payable(seller).transfer(msg.value);

}

/* Returns only items that a user has purchased */
    function fetchMyNFTs() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].owner == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

/* Returns only items a user has listed */
    function fetchItemsListed() public view returns (MarketItem[] memory) {
        uint256 totalItemCount = _tokenIds.current();
        uint256 itemCount = 0;
        uint256 currentIndex = 0;

        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                itemCount += 1;
            }
        }

        MarketItem[] memory items = new MarketItem[](itemCount);
        for (uint256 i = 0; i < totalItemCount; i++) {
            if (idToMarketItem[i + 1].seller == msg.sender) {
                uint256 currentId = i + 1;
                MarketItem storage currentItem = idToMarketItem[currentId];
                items[currentIndex] = currentItem;
                currentIndex += 1;
            }
        }
        return items;
    }

    function transferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) public  {
        require(
            from == _msgSender() || isApprovedForAll(from, _msgSender()),
            "ERC1155: caller is not token owner nor approved"
        );
        _safeTransferFrom(from, to, id, amount, data);
    }

    function onERC1155Received(
        address _operator,
        address _from,
        uint256 _id,
        uint256 _value,
        bytes calldata _data
    ) external returns (bytes4) {
        return
            bytes4(
                keccak256(
                    "onERC1155Received(address,address,uint256,uint256,bytes)"
                )
            );
    }

// Get URI link of any Token.
  function uri(uint256 tokenId) public view virtual override returns (string memory) {
        string memory tokenURI = _tokenURIs[tokenId];

        // If token URI is set, concatenate base URI and tokenURI (via abi.encodePacked).
        return bytes(tokenURI).length > 0 ? string(abi.encodePacked(_baseURI, tokenURI)) : super.uri(tokenId);
    }

//To chnage the URL String after the contract is deployed
    function setURI(string memory newuri) public onlyOwner {
        _setURI(newuri);
    }

    function _setTokenUri(uint256 tokenId, string memory tokenURI) private {
        _tokenURIs[tokenId] = tokenURI;
    }

     function balanceOfAddress(uint256 itemId) public view returns (uint256) {
        return _balances[itemId][address(this)];
    }

   function burnNFT(uint256 itemId,uint256 amount) public 
    {
        uint256 tokenId = idToMarketItem[itemId].tokenId;
         address owner = idToMarketItem[itemId].owner;
         require(owner==msg.sender || owner==address(this),"Only owner can burn the Token");
        _burn(owner,tokenId,amount);
        //  uint256 amt= _balances[itemId][owner];
        //  console.log("amt:",amt);
        // if(amt==0)
        // {
        //    address sel= idToMarketItem[itemId].seller;
        //   address own=  idToMarketItem[itemId].owner;
        //     _safeTransferFrom(sel, own, tokenId, amt, "");
        // }
    }   


function _mint(
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override{
        require(to != address(0), "ERC1155: mint to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray1(id);
        uint256[] memory amounts = _asSingletonArray1(amount);

        _beforeTokenTransfer(operator, address(0), to, ids, amounts, data);

        _balances[id][to] += amount;
        emit TransferSingle(operator, address(0), to, id, amount);

        _afterTokenTransfer(operator, address(0), to, ids, amounts, data);

      //  _doSafeTransferAcceptanceCheck(operator, address(0), to, id, amount, data);
    }

function _burn(
        address from,
        uint256 id,
        uint256 amount
    ) internal virtual override{
        require(from != address(0), "ERC1155: burn from the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray1(id);
        uint256[] memory amounts = _asSingletonArray1(amount);

        _beforeTokenTransfer(operator, from, address(0), ids, amounts, "");

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: burn amount exceeds balance");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }

        emit TransferSingle(operator, from, address(0), id, amount);

        _afterTokenTransfer(operator, from, address(0), ids, amounts, "");
    }


    function _safeTransferFrom(
        address from,
        address to,
        uint256 id,
        uint256 amount,
        bytes memory data
    ) internal virtual override{
        require(to != address(0), "ERC1155: transfer to the zero address");

        address operator = _msgSender();
        uint256[] memory ids = _asSingletonArray1(id);
        uint256[] memory amounts = _asSingletonArray1(amount);

        _beforeTokenTransfer(operator, from, to, ids, amounts, data);

        uint256 fromBalance = _balances[id][from];
        require(fromBalance >= amount, "ERC1155: insufficient balance for transfer");
        unchecked {
            _balances[id][from] = fromBalance - amount;
        }
        _balances[id][to] += amount;

        emit TransferSingle(operator, from, to, id, amount);

        _afterTokenTransfer(operator, from, to, ids, amounts, data);

      //  _doSafeTransferAcceptanceCheck(operator, from, to, id, amount, data);
    }

    

        function _asSingletonArray1(uint256 element) private pure returns (uint256[] memory) {
        uint256[] memory array = new uint256[](1);
        array[0] = element;

        return array;
    }
}
