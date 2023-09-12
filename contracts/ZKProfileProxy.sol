pragma solidity ^0.8.9;

import "../lib/openzeppelin-contracts/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import "./Governable.sol";

contract ZKProfileProxy is Governable, ERC1967Proxy {

  constructor(address _logic, bytes memory _data) payable Governable() ERC1967Proxy(_logic, _data) { }

  function upgradeTo(address _logic) external onlyGov {
    _upgradeTo(_logic);
  }

}
