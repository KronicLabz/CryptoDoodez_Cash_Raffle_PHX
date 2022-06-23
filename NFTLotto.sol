//SPDX-License-Identifier:MIT
pragma solidity 0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";


contract NFTLotto is ERC721Enumerable, Ownable {
  using Strings for uint256;

  string baseURI;
  string public baseExtension = ".json";
  uint256 public cost = 75 ether;
  uint256 public maxSupply = 50;
  uint256 public headStart = block.timestamp + 1 days;
  bool public paused = false;
  bool public revealed = false;
  string public notRevealedUri;
 
  
  constructor(
    string memory _initBaseURI,
    string memory _initNotRevealedUri
  ) ERC721("CryptoDoodez Crazy Cash Raffle", "CDC") {
    setBaseURI(_initBaseURI);
    setNotRevealedURI(_initNotRevealedUri);
  }

  // internal
  function _baseURI() internal view virtual override returns (string memory) {
    return baseURI;
  }

  // public
  function mint() public payable {
    uint256 supply = totalSupply();
    require(!paused, "Contract is paused!");
    require(supply + 1 <= maxSupply, "Max supply reached!");
    require(msg.sender != owner(), "Owner can not mint!");
    require(msg.value >= cost, "Not enough funds!");
    
    address payable giftAddress = payable(msg.sender);
    uint256 giftValue;
    
    if(supply > 0) {
        giftAddress = payable(ownerOf(randomNum(supply, block.timestamp, supply + 1) + 1));
        giftValue = supply + 1 == maxSupply ? address(this).balance * 40 / 100 : msg.value * 60 / 100;
    }
    
    _safeMint(msg.sender, supply + 1);

    if(supply > 0) {
        (bool success, ) = payable(giftAddress).call{value: giftValue}("");
        require(success, "Could not send value!");
    }
  }

  function walletOfOwner(address _owner)
    public
    view
    returns (uint256[] memory)
  {
    uint256 ownerTokenCount = balanceOf(_owner);
    uint256[] memory tokenIds = new uint256[](ownerTokenCount);
    for (uint256 i; i < ownerTokenCount; i++) {
      tokenIds[i] = tokenOfOwnerByIndex(_owner, i);
    }
    return tokenIds;
  }
  
  function randomNum(uint256 _mod, uint256 _seed, uint256 _salt) public view returns(uint256) {
      uint256 num = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, _seed, _salt))) % _mod;
      return num;
  }

  function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
  {
    require(
      _exists(tokenId),
      "ERC721Metadata: URI query for nonexistent token"
    );
    
    if(revealed == false) {
        return notRevealedUri;
    }

    string memory currentBaseURI = _baseURI();
    return bytes(currentBaseURI).length > 0
        ? string(abi.encodePacked(currentBaseURI, tokenId.toString(), baseExtension))
        : "";
  }

  //only owner
  function reveal() public onlyOwner() {
      revealed = true;
  }
  
  function setCost(uint256 _newCost) public onlyOwner() {
    cost = _newCost;
  }

  function setNotRevealedURI(string memory _notRevealedURI) public onlyOwner {
    notRevealedUri = _notRevealedURI;
  }

  function setBaseURI(string memory _newBaseURI) public onlyOwner {
    baseURI = _newBaseURI;
  }

  function setBaseExtension(string memory _newBaseExtension) public onlyOwner {
    baseExtension = _newBaseExtension;
  }

  function pause(bool _state) public onlyOwner {
    paused = _state;
  }
  
  function withdraw() public payable onlyOwner {
    uint256 supply = totalSupply();
    require(supply == maxSupply || block.timestamp >= headStart, "Can not withdraw yet.");
    (bool d, ) = payable(0x0acdDb50af0Db27cD34187bB90194093547c254e).call{value: address(this).balance * 40 / 100}("");
    require(d);
    (bool s, ) = payable(msg.sender).call{value: address(this).balance * 60 / 100}("");
    require(s);
  }
}
