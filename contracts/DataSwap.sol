pragma solidity ^0.8.9;

import "./Governable.sol";
import "./IZKProfile.sol";

contract DataSwap is Governable {
  // user => (cid => count)
  mapping (address => mapping (uint256 => uint256)) public buyRecords;
  // cid => price
  mapping (uint256 => uint256) public tagPrices;

  event Buy(address indexed _buyer, uint256 indexed _cid, uint256 _count, uint256 _value);
  event Send(address indexed _sender, uint256 indexed _cid, string _title, string _content);

  constructor() Governable() { }

  function setupPrice(uint256 cid, uint256 price) external onlyGov {
    tagPrices[cid] = price;
  }

  function release(address payable[] memory _addresses, uint256 _cid) external onlyGov {
    require(tagPrices[_cid] > 0, "DataSwap: tag not swappable");
    require(address(this).balance >= tagPrices[_cid], "DataSwap: insufficient balance");

    uint256 benefit = tagPrices[_cid] / _addresses.length;

    for (uint256 i = 0; i < _addresses.length; i++)
      _addresses[i].transfer(benefit);
  }

  function buy(uint256 _cid) external payable {
    require(tagPrices[_cid] > 0, "DataSwap: tag not swappable");
    require(msg.value >= tagPrices[_cid], "DataSwap: insufficient payment");

    uint256 count = msg.value / tagPrices[_cid];

    buyRecords[msg.sender][_cid] += count;

    emit Buy(msg.sender, _cid, count, msg.value);
  }

  function send(uint256 _cid, string memory _title, string memory _content) external {
    require(buyRecords[msg.sender][_cid] > 0, "DataSwap: insufficient count");

    buyRecords[msg.sender][_cid]--;

    emit Send(msg.sender, _cid, _title, _content);
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
