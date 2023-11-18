pragma solidity ^0.8.9;

import "./Governable.sol";
import "./IZKProfile.sol";

contract DataSwap is Governable {

  IZKProfile public zkProfile;

  uint256 constant public MAX_COUNT = type(uint256).max;

  // user => (key => value)
  mapping (address => mapping (bytes32 => uint256)) public buyRecords;
  // user => key[]
  mapping (address => bytes32[]) public buyKeys;
  // key => tagId[]
  mapping (bytes32 => uint256[]) public keys;
  // cid => price
  mapping (uint256 => uint256) public tagPrices;

  event Buy(address indexed _buyer, byte32 indexed _key, uint256 _value);
  event Send(address indexed _sender, byte32 indexed _key, string _title, string _content);

  constructor(IZKProfile _zkProfile) Governable() {
    zkProfile = _zkProfile;
  }

  function setupProfile(IZKProfile _zkProfile) external onlyGov {
    zkProfile = _zkProfile;
  }
  function setupPrice(uint256 cid, uint256 price) external onlyGov {
    tagPrices[cid] = price;
  }

  function release(address payable[] memory _addresses, bytes32 _key) external onlyGov {
    uint256[] memory _tagIds = keys[_key];

    uint256 maxPrice = getPrice(_key);
    require(maxPrice > 0, "DataSwap: invalid price");
    require(address(this).balance >= maxPrice, "DataSwap: insufficient balance");

    uint256 benefit = maxPrice / _addresses.length;

    for (uint256 i = 0; i < _addresses.length; i++)
      _addresses[i].transfer(benefit);
  }

  function getKey(uint256[] _tagIds) public view returns (bytes32 memory) {
    return keccak256(abi.encodePacked(_tagIds));
  }
  function getPrice(bytes32 _key) public view returns (uint256) {
    uint256[] memory _tagIds = keys[_key];

    uint256 maxPrice = 0;
    for (uint256 i = 0; i < _tagIds.length; i++) {
      uint256 price = tagPrices[_tagIds[i]];
      maxPrice = price > maxPrice ? price : maxPrice;
    }
    return maxPrice;
  }

  function sendCount(address _owner, bytes32 _key) public view returns (uint256) {
    uint256 maxPrice = getPrice(_key);
    if (maxPrice == 0) return MAX_COUNT;
    return buyRecords[_owner][_key] / maxPrice;
  }

  function buy(uint256[] _tagIds) external payable {
    uint256 maxPrice = 0;
    for (uint256 i = 0; i < _tagIds.length; i++) {
      uint256 price = tagPrices[_tagIds[i]];
      require(price > 0, "DataSwap: tag not swappable");

      maxPrice = price > maxPrice ? price : maxPrice;
    }
    require(msg.value >= maxPrice, "DataSwap: insufficient payment");

    bytes32 key = getKey(_tagIds);
    keys[key] = _tagIds;
    buyKeys[msg.sender].push(key);
    buyRecords[msg.sender][key] += msg.value;

    emit Buy(msg.sender, key, count, msg.value);
  }

  function send(bytes32 _key, string memory _title, string memory _content) external {
    uint256 maxPrice = getPrice(_key);
    require(buyRecords[msg.sender][_key] >= maxPrice, "DataSwap: insufficient count");

    buyRecords[msg.sender][_key] -= maxPrice;

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
