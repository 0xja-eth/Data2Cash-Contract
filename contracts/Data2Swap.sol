pragma solidity ^0.8.9;

import "./Governable.sol";
import "./IZKProfile.sol";
import "../lib/openzeppelin-contracts/contracts/token/ERC1155/ERC1155.sol";

contract Data2Swap is Governable {

  IZKProfile public zkProfile;

  uint256 constant public MAX_COUNT = type(uint256).max;

//  uint256 public supply;
  // user => (key => value)
  mapping (address => mapping (bytes32 => uint256)) public buyRecords;
  // user => key[]
  mapping (address => bytes32[]) public buyKeys;
  // key => tagId[]
  mapping (bytes32 => uint256[]) public keyTagIds;

  // cid => price
  mapping (uint256 => uint256) public tagPrices;

  event Buy(address indexed _buyer, bytes32 indexed _key, uint256 _count, uint256 _value);
  event Send(address indexed _sender, bytes32 indexed _key, string _title, string _content);

  constructor(IZKProfile _zkProfile) Governable() {
    zkProfile = _zkProfile;
  }

  function setupProfile(IZKProfile _zkProfile) external onlyGov {
    zkProfile = _zkProfile;
  }
  function setupPrice(uint256 _tagId, uint256 _price) external onlyGov {
//    require(supply == 0, "DataSwap: already setup");
    tagPrices[_tagId] = _price;
  }

  function release(address payable[] memory _addresses, bytes32 _key) external onlyGov {
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

  function getKey(uint256[] memory _tagIds) public pure returns (bytes32) {
    return keccak256(abi.encodePacked(_tagIds));
  }
  function getPrice(bytes32 _key) public view returns (uint256) {
    uint256[] memory _tagIds = keyTagIds[_key];

    uint256 maxPrice = 0;
    for (uint256 i = 0; i < _tagIds.length; i++) {
      uint256 price = tagPrices[_tagIds[i]];
      maxPrice = price > maxPrice ? price : maxPrice;
    }
    return maxPrice;
  }

  function buy(uint256[] memory _tagIds) external payable {
    uint256 maxPrice = 0;
    for (uint256 i = 0; i < _tagIds.length; i++) {
      uint256 price = tagPrices[_tagIds[i]];
      require(price > 0, "DataSwap: tag not swappable");

      maxPrice = price > maxPrice ? price : maxPrice;
    }
    require(msg.value >= maxPrice, "DataSwap: insufficient payment");

    uint256 count = msg.value / maxPrice;

    bytes32 key = getKey(_tagIds);
    keyTagIds[key] = _tagIds;
    buyKeys[msg.sender].push(key);
    buyRecords[msg.sender][key] += count;
//    supply += count;

    emit Buy(msg.sender, key, count, msg.value);
  }

  function send(bytes32 _key, string memory _title, string memory _content) external {
    require(buyRecords[msg.sender][_key] >= 1, "DataSwap: insufficient count");

    buyRecords[msg.sender][_key] -= 1;
//    supply--;

    emit Send(msg.sender, _key, _title, _content);
  }
}
