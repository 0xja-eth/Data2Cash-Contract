pragma solidity ^0.8.9;

import "./Governable.sol";
import "./IZKProfile.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract Data2SwapERC1155 is ERC1155, Governable {

  IZKProfile public zkProfile;

  uint256 constant public MAX_COUNT = type(uint256).max;

  uint256 public supply;
  // user => (key => value)
//  mapping (address => mapping (bytes32 => uint256)) public buyRecords;
  // user => key[]
//  mapping (address => bytes32[]) public buyKeys;
//  mapping (address => uint256[]) public buyKeys;
  // key => tagId[]
//  mapping (bytes32 => uint256[]) public keyTagIds;
  mapping (uint256 => uint256[]) public keyTagIds;

  uint256[] public keys;

  // cid => price
  mapping (uint256 => uint256) public tagPrices;

  event Buy(address indexed _buyer, uint256 indexed _key, uint256 _count, uint256 _value);
  event Send(address indexed _sender, uint256 indexed _key, string _title, string _content);

  constructor(IZKProfile _zkProfile, string memory _uri) ERC1155(_uri) Governable() {
    zkProfile = _zkProfile;
  }

  function setupUri(string memory _uri) external onlyGov {
    _setURI(_uri);
  }
  function setupProfile(IZKProfile _zkProfile) external onlyGov {
    zkProfile = _zkProfile;
  }
  function setupPrice(uint256 _tagId, uint256 _price) external onlyGov {
    require(supply == 0, "DataSwap: already setup");
    tagPrices[_tagId] = _price;
  }

  function release(address payable[] memory _addresses, uint256 _key) external onlyGov {
    uint256[] memory tagIds = keyTagIds[_key];

    for (uint256 i = 0; i < tagIds.length; i++)
      for (uint256 j = 0; j < _addresses.length; j++)
        require(zkProfile.verifyTag(_addresses[j], tagIds[i]), "DataSwap: address do not own the tag");

    uint256 maxPrice = getPrice(_key);
    require(maxPrice > 0, "DataSwap: invalid price");
    require(address(this).balance >= maxPrice, "DataSwap: insufficient balance");

    uint256 benefit = maxPrice / _addresses.length;

    for (uint256 i = 0; i < _addresses.length; i++)
      _addresses[i].transfer(benefit);
  }

//  function getKey(uint256[] memory _tagIds) public view returns (bytes32) {
//    return keccak256(abi.encodePacked(_tagIds));
//  }
  function getKey(uint256[] memory _tagIds) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(_tagIds)));
  }
  function getPrice(uint256 _key) public view returns (uint256) {
    uint256[] memory _tagIds = keyTagIds[_key];

    uint256 maxPrice = 0;
    for (uint256 i = 0; i < _tagIds.length; i++) {
      uint256 price = tagPrices[_tagIds[i]];
      maxPrice = price > maxPrice ? price : maxPrice;
    }
    return maxPrice;
  }

//  function sendCount(address _owner, bytes32 _key) public view returns (uint256) {
//    uint256 maxPrice = getPrice(_key);
//    if (maxPrice == 0) return MAX_COUNT;
//    return balanceOf(_owner, uint256(_key)) / maxPrice;
////    return buyRecords[_owner][_key] / maxPrice;
//  }

  function buy(uint256[] memory _tagIds) external payable {
    uint256 maxPrice = 0;
    for (uint256 i = 0; i < _tagIds.length; i++) {
      uint256 price = tagPrices[_tagIds[i]];
      require(price > 0, "DataSwap: tag not swappable");

      maxPrice = price > maxPrice ? price : maxPrice;
    }
    require(msg.value >= maxPrice, "DataSwap: insufficient payment");

    uint256 key = getKey(_tagIds);
    keys.push(key); // ERC1155 TokenIDs
    keyTagIds[key] = _tagIds;
//    buyKeys[msg.sender].push(key);
//    buyRecords[msg.sender][key] += msg.value;

    uint256 count = msg.value / maxPrice;
    _mint(msg.sender, key, count, "");
    supply += count;

    emit Buy(msg.sender, key, count, msg.value);
  }

  function send(uint256 _key, string memory _title, string memory _content) external {
//    require(buyRecords[msg.sender][_key] >= 1, "DataSwap: insufficient count");
    require(balanceOf(msg.sender, _key) >= 1, "DataSwap: insufficient count");

//    buyRecords[msg.sender][_key] -= 1;
    _burn(msg.sender, _key, 1);
    supply--;

    emit Send(msg.sender, _key, _title, _content);
  }

//  function getMaxCount(uint256 _cid) external view returns (uint256) {
//    return zkProfile.getTokenIdsByCid(_cid).length;
//  }

//  function buy(uint256 _cid, uint256 _count) external payable {
//    require(tagPrices[_cid] > 0, "DataSwap: tag not swappable");
//    require(msg.value > tagPrices[_cid] * _count, "DataSwap: insufficient payment");
//
//    uint256[] memory tokenIds = zkProfile.getTokenIdsByCid(_cid);
//    uint256 maxCount = tokenIds.length;
//
//    require(buyRecords[msg.sender][_cid] + _count <= maxCount, "DataSwap: exceed max count");
//
//    uint256 start = buyRecords[msg.sender][_cid];
//    buyRecords[msg.sender][_cid] += _count;
//
//    for (uint256 i = start; i < start + _count; i++) {
//      uint256 tokenId = tokenIds[i];
//      address owner = zkProfile.ownerOf(tokenId);
//      owner.transfer(tagPrices[_cid]);
//    }
//
//    emit Buy(_to, _tokenId, _price);
//  }
}
