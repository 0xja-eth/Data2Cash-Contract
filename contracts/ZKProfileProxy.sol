pragma solidity ^0.8.9;

import "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract ZKProfileProxy is ERC1967Proxy {

  constructor(address _logic, bytes memory _data) payable ERC1967Proxy(_logic, _data) {

  }

}
