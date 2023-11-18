pragma solidity ^0.8.9;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./IHydraS1Verifier.sol";
import "./EditionMetadataRenderer.sol";
import "./Governable.sol";
import "./IZKProfile.sol";

contract ZKProfile is Governable, ERC721, EditionMetadataRenderer, IZKProfile {

  // Define the struct for your NFT's metadata
  struct NFTMetadata {
    uint256 tokenId;
    address owner;
    uint256[] tagIds;
  }

  bool public initialized = false;
  IHydraS1Verifier public hydraS1Verifier;

  // nullifier => isExpired
  mapping (uint256 => bool) isNullifierExpired;
  // tokenId => NFTMetadata
  mapping (uint256 => NFTMetadata) public tokens;

  // ffffffffffffffffffff
  uint256 public constant EMPTY_TOKEN_ID = 2 ** 80 - 1;

  uint256 public supply;

  event ZKProof(
    address indexed _to,
    uint[2] _a, uint[2][2] _b, uint[2] _c,
    uint[5] _input
  );

  constructor() Governable() ERC721("ZKProfile", "ZKP") { }

  modifier beforeInitialized() {
    require(!initialized, "ZKProfile: already initialized");
    _;
  }

  function initialize(
    address _hydraS1Verifier,
    string memory _description,
    string memory _imageUrl,
    string memory _externalUrl) external beforeInitialized onlyGov {
    hydraS1Verifier = IHydraS1Verifier(_hydraS1Verifier);

    description = _description;
    imageUrl = _imageUrl;
    externalUrl = _externalUrl;

    initialized = true;
  }
  function changeInfo(
    string memory _description,
    string memory _imageUrl,
    string memory _externalUrl) external onlyGov {

    description = _description;
    imageUrl = _imageUrl;
    externalUrl = _externalUrl;
  }

//  function getTokenIdsByCid(uint256 tagId) public view returns (uint256[] memory) {
//    uint256[] memory tokenIds = new uint256[](supply); // 假设供应量是合约的状态变量
//    uint256 count = 0;
//
//    for (uint256 i = 0; i < supply; i++) {
//      if (tokens[i].tagIds.length > 0) {
//        for (uint256 j = 0; j < tokens[i].tagIds.length; j++) {
//          if (tokens[i].tagIds[j] == tagId) {
//            tokenIds[count] = i;
//            count++;
//            break;
//          }
//        }
//      }
//    }
//
//    // 调整数组大小以匹配实际找到的tokenId数量
//    uint256[] memory result = new uint256[](count);
//    for (uint256 k = 0; k < count; k++) {
//      result[k] = tokenIds[k];
//    }
//
//    return result;
//  }

  // Create a new NFT
  function pushZKProof(
    uint[2] memory _a,
    uint[2][2] memory _b,
    uint[2] memory _c,
    uint[5] memory _input
  ) public {
    // check proof
    require(!isNullifierExpired[_input[4]], "Invalid Nullifier");
    require(hydraS1Verifier.verifyProof(_a, _b, _c, _input), "Invalid Proof");

    // mint new token if tokenId
    address mintTo = address(getMintTo(_input[0]));
    uint256 tokenId = getTokenId(_input[0]);

    if (tokenId == EMPTY_TOKEN_ID) { // 没有mint，但要二次确认
      tokenId = getTokenIdByAddress(mintTo);
      if (tokenId != EMPTY_TOKEN_ID)
        tokens[tokenId].tagIds.push(_input[3]);
      else {
        // uint256 tokenId = nfts.length;
        _safeMint(mintTo, supply);
        tokenId = supply;
        tokens[supply].tokenId = tokenId;
        tokens[supply].owner = mintTo;
        tokens[supply].tagIds.push(_input[3]);

        supply += 1;
      }
    } else {
      require(tokenId < supply, "Invalid TokenId");
      tokens[tokenId].tagIds.push(_input[3]);
    }

    isNullifierExpired[_input[4]] = true;

    emit ZKProof(mintTo, _a, _b, _c, _input);
  }
  function pushZKProofs(
    uint[2][] memory _a,
    uint[2][2][] memory _b,
    uint[2][] memory _c,
    uint[5][] memory _input
  ) external {
    uint256 length = _input.length;
    require(_a.length == length && _b.length == length && _c.length == length, "Invalid length");

    for (uint256 i = 0; i < length; i++)
      pushZKProof(_a[i], _b[i], _c[i], _input[i]);
  }

  // Get the metadata of an NFT
  function getNFTMetadata(uint256 _tokenId) external view returns (NFTMetadata memory) {
    require(_exists(_tokenId), "Token ID does not exist");
    return tokens[_tokenId];
  }

  // Shift the uint256 value to the right by 80 bits to get the last 20 bytes
  function getMintTo(uint256 _number) public pure returns (bytes20) {
    return bytes20(uint160(_number >> 80));
  }
  // Define a mask with the desired bits set to 1
  // Perform a bitwise AND with the mask to get the last 12 bytes
  function getTokenId(uint256 _number) public pure returns (uint256) {
    return _number & uint256(EMPTY_TOKEN_ID);
  }

  function getTokenIdByAddress(address _owner) public view returns (uint256) {
    for (uint256 i = 0; i < supply; ++i)
      if (tokens[i].owner == _owner) return i;

    return uint256(2 ** 80 - 1);
  }

  function verifyTag(address _owner, uint256 _tagId) public view returns (bool) {
    for (uint256 i = 0; i < supply; ++i)
      if (tokens[i].owner == _owner) {
        for (uint256 j = 0; j < tokens[i].tagIds.length; ++j)
          if (tokens[i].tagIds[j] == _tagId) return true;
        return false;
      }
    return false;
  }

  /// @notice Get the base64-encoded json metadata for a token
  /// @param tokenId the token id to get the metadata for
  /// @return base64-encoded json metadata object
  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
    require(ownerOf(_tokenId) != address(0), "No token");

    return createTokenMetadata(name(), _tokenId, 0);
  }

  function calcPropertiesJson(uint256 _tokenId) internal view override returns (string memory) {
    uint256 len = tokens[_tokenId].tagIds.length;
    uint256 lengthMinusOne = len - 1;

    string memory buffer = '';

    for (uint256 i = 0; i < lengthMinusOne; ) {
      buffer = string.concat(
        buffer,
        stringifyStringAttribute(
          "Tag",
          LibString.toString(tokens[_tokenId].tagIds[i])),
        ","
      );

      // counter increment can not overflow
      ++i;
    }

    return string.concat(
      buffer,
      stringifyStringAttribute(
        "Tag",
        LibString.toString(tokens[_tokenId].tagIds[lengthMinusOne]))
    );
  }

  //   function _transfer(
  //     address from,
  //     address to,
  //     uint256 tokenId
  //   ) internal override {
  //     require(false, "SBT: SBT Can't Be Transferred");
  //   }
  //   function addProperty(uint256 tokenId, string memory name, string memory value) private {
  //     properties[tokenId].push(Attribute({
  //       name: name, value: value
  //     }));
  //   }
}
