pragma solidity ^0.5.9;
pragma experimental ABIEncoderV2;

import 'github.com/OpenZeppelin/openzeppelin-solidity/blob/v2.5.0/contracts/token/ERC721/ERC721Full.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/blob/v2.5.0/contracts/token/ERC721/ERC721Burnable.sol';
import 'github.com/OpenZeppelin/openzeppelin-solidity/blob/v2.5.0/contracts/ownership/Ownable.sol';

contract OwnableDelegateProxy { }

contract ProxyRegistry {
    mapping(address => OwnableDelegateProxy) public proxies;
}

/**
 * @title TradeableERC721Token
 * TradeableERC721Token - ERC721 contract that whitelists a trading address, and has minting functionality.
 */
contract TradeableERC721Token is ERC721Full, ERC721Burnable, Ownable {

    struct oxR{
        string uri;
        bool isSponsor;
        bool exist;
    }

  mapping (uint256 => oxR) _oxRs;

  address proxyRegistryAddress;
  uint256 private _currentTokenId = 0;

  event SponsorToCollectible(string _uri);

  constructor(string memory _name, string memory _symbol, address _proxyRegistryAddress) ERC721Full(_name, _symbol) public {
    proxyRegistryAddress = _proxyRegistryAddress;
  }
  
  /**
    * @dev Mints bulk amount to address (owner)
    * @param _to address of the future owner of the token
    */
  function bulkMintTo(uint256 mintAmount, address _to, string memory _uri, bool _isSponsor) public onlyOwner {
    for (uint256 i = 0; i < mintAmount; i++) {
        internalMinter(_to, _uri, _getNextTokenId(), _isSponsor);
     }
  }

  /**
    * @dev Mints bulk amount of same token with given meta to array of addresses
    */
  function bulkMintArray(address[] memory receivers, string memory _uri, bool _isSponsor) public onlyOwner {
     for (uint256 i = 0; i < receivers.length; i++) {
         internalMinter(receivers[i], _uri, _getNextTokenId(), _isSponsor);
     }
  }
  
  /**
    * @dev Mints bulk multiple tokens to single address
    */
  function bulkMintTokens(address receivers, string[] memory _uri, bool _isSponsor) public onlyOwner {
     for (uint256 i = 0; i < _uri.length; i++) {
         internalMinter(receivers, _uri[i], _getNextTokenId(), _isSponsor);
     }
  }

  /**
    * @dev Mints a token to an address with a tokenURI.
    * @param _to address of the future owner of the token
    */
  function mintTo(address _to, string memory _uri, bool _isSponsor) public onlyOwner {
    internalMinter(_to, _uri, _getNextTokenId(), _isSponsor);
  }

    //inernal func for minting new tokens
  function internalMinter(address _to, string memory _uri, uint256 _newTokenId, bool _isSponsor) private{
      oxR memory _newoxR = oxR(_uri, _isSponsor, true);
      _oxRs[_newTokenId] = _newoxR;
    _mint(_to, _newTokenId);
    _incrementTokenId();
  }

//Process of converting a Sponsor token to collectible token
//Used mainly once an owner claims their sponsorship, then converts to collectible as proof of sponsorship
  function convertSponsorToCollectible(uint256 _tokenId, string memory _newUri) public {
        require(tokenListContains(_tokenId) == true);
        require(_oxRs[_tokenId].isSponsor == true);
        address tokenOwner = ownerOf(_tokenId);
        bool canUpdate = false;
        if(msg.sender == owner()){
            canUpdate = true;
        }
        
        if(msg.sender == tokenOwner){
            canUpdate = true;
        }
        
        if(canUpdate){
            //Sponsor token is now converted to collctible wih new meta
            oxR memory _newoxR = oxR(_newUri, false, true);
            _oxRs[_tokenId] = _newoxR;
            emit SponsorToCollectible(_newUri);
        }
  }

    function tokenListContains(uint256 _tokenId) public view returns (bool){
        return _oxRs[_tokenId].exist;
    }

  /**
    * @dev calculates the next token ID based on value of _currentTokenId 
    * @return uint256 for the next token ID
    */
  function _getNextTokenId() private view returns (uint256) {
    return _currentTokenId.add(1);
  }

  /**
    * @dev increments the value of _currentTokenId 
    */
  function _incrementTokenId() private  {
    _currentTokenId++;
  }

  function baseTokenURI() public view returns (string memory) {
    return "";
  }

//Fetches the token URI based on tokenID
  function tokenURI(uint256 _tokenId) external view returns (string memory) {
    return _oxRs[_tokenId].uri;
  }
  
  //return the struct data for the given token id 
  function tokenStruct(uint256 _tokenId) external view returns (string memory uri, bool isSponsor, bool exist){
       require(tokenListContains(_tokenId) == true);
       return (_oxRs[_tokenId].uri, _oxRs[_tokenId].isSponsor, _oxRs[_tokenId].exist);
  }

  /**
   * Override isApprovedForAll to whitelist user's OpenSea proxy accounts to enable gas-less listings.
   */
  function isApprovedForAll(
    address owner,
    address operator
  )
    public
    view
    returns (bool)
  {
    // Whitelist OpenSea proxy contract for easy trading.
    ProxyRegistry proxyRegistry = ProxyRegistry(proxyRegistryAddress);
    if (address(proxyRegistry.proxies(owner)) == operator) {
        return true;
    }

    return super.isApprovedForAll(owner, operator);
  }

  //Update proxy address, mainly used for OpenSea
    function updateProxyAddress(address _proxy) public onlyOwner {
        proxyRegistryAddress = _proxy;
    }
}

/**
 * @title 0xR
 * 0xRacing : Tokenized eSports / eRacing team, collcetibles and tokenized sponsorship 
 */
contract OxRacing is TradeableERC721Token {
  constructor(address _proxyRegistryAddress) TradeableERC721Token("0xRacing", "0xR", _proxyRegistryAddress) public {  }
}