pragma solidity ^0.8.9;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";

interface IZKProfile is IERC721 {
  function getTokenIdsByCid(uint256 cid) external view returns (uint256[] memory);
  function getTokenIdByAddress(address owner) external view returns (uint256);
}
