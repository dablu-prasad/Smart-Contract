// SPDX-License-Identifier: MIT
pragma solidity 0.8.0;
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
//import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
//import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract NFTERC721 
{
   using Counters for Counters.Counter;
    using SafeMath for uint256;

   event Transfer(address indexed sender,address indexed receiver,uint256 tokenid);

     // Mapping owner address to token count
    mapping(address => uint256) public _balances;

    // Mapping from token ID to owner address
    mapping(uint256 => address) public _owners;

     // Mapping from token ID to approved address
    mapping(uint256 => address) public _tokenApprovals;

//Mint Token
function _mint(address to, uint256 tokenId) public  {
        require(to != address(0), "ERC721: mint to the zero address");
        require(!_exists(tokenId), "ERC721: token already minted");
        //_balances[to] += 1;
        _balances[to]=_balances[to].add(1);
        _owners[tokenId] = to;

        emit Transfer(address(0), to, tokenId);
    }

//Burn Token
function _burn(uint256 tokenId) public  {
        address owner = NFTERC721.ownerOf(tokenId);
       // Clear approvals
        delete _tokenApprovals[tokenId];
      // _balances[owner] -= 1;
        _balances[owner]=_balances[owner].sub(1);
        delete _owners[tokenId];
        emit Transfer(owner, address(0), tokenId);
    }

function _exists(uint256 tokenId) internal view virtual returns (bool) {
        return _owners[tokenId] != address(0);
    }

   function ownerOf(uint256 tokenId) public view returns (address) {
        address owner = _owners[tokenId];
        require(owner != address(0), "ERC721: invalid token ID");
        return owner;
    }

}
