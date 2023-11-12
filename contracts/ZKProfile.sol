pragma solidity ^0.8.9;

import "../lib/openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import "./IHydraS1Verifier.sol";
import "./EditionMetadataRenderer.sol";
import "./Governable.sol";
import "./IZKProfile.sol";

contract ZKProfile is Governable, ERC721, EditionMetadataRenderer, IZKProfile {

  bool public initialized = false;

  uint256 supply;
  IHydraS1Verifier hydraS1Verifier;

  // ffffffffffffffffffff
  uint256 public constant EMPTY_TOKEN_ID = 2 ** 80 - 1;

  // Define the struct for your NFT's metadata
  struct NFTMetadata {
    uint256 tokenId;
    address owner;
    uint256[] cids;
  }

  // key: nullifier
  mapping (uint256 => bool) isNullifierExpired;

  // key: tokenId
  mapping (uint256 => NFTMetadata) tokens;

  event ZKProof(
    address indexed to,
    uint[2] a, uint[2][2] b, uint[2] c,
    uint[5] input
  );

  constructor() Governable() ERC721("ZKProfile", "ZKP") { }

  modifier beforeInitialized() {
    require(!initialized, "ZKProfile: already initialized");
    _;
  }

  function initialize(
    address hydraS1Verifier_,
    string memory _description,
    string memory _imageUrl,
    string memory _externalUrl) external beforeInitialized onlyGov {
    hydraS1Verifier = IHydraS1Verifier(hydraS1Verifier_);

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

  function getTokenIdsByCid(uint256 cid) public view returns (uint256[] memory) {
    uint256[] memory tokenIds = new uint256[](supply); // 假设供应量是合约的状态变量
    uint256 count = 0;

    for (uint256 i = 0; i < supply; i++) {
      if (tokens[i].cids.length > 0) {
        for (uint256 j = 0; j < tokens[i].cids.length; j++) {
          if (tokens[i].cids[j] == cid) {
            tokenIds[count] = i;
            count++;
            break;
          }
        }
      }
    }

    // 调整数组大小以匹配实际找到的tokenId数量
    uint256[] memory result = new uint256[](count);
    for (uint256 k = 0; k < count; k++) {
      result[k] = tokenIds[k];
    }

    return result;
  }

  // Create a new NFT
  function pushZKProof(
    uint[2] memory a,
    uint[2][2] memory b,
    uint[2] memory c,
    uint[5] memory input
  ) public {
    // check proof
    require(!isNullifierExpired[input[4]], "Invalid Nullifier");
    require(hydraS1Verifier.verifyProof(a, b, c, input), "Invalid Proof");

    // mint new token if tokenId
    address mintTo = address(getMintTo(input[0]));
    uint256 tokenId = getTokenId(input[0]);

    if (tokenId == EMPTY_TOKEN_ID) { // 没有mint，但要二次确认
      tokenId = getTokenIdByAddress(mintTo);
      if (tokenId != EMPTY_TOKEN_ID)
        tokens[tokenId].cids.push(input[3]);
      else {
        // uint256 tokenId = nfts.length;
        _safeMint(mintTo, supply);
        tokenId = supply;
        tokens[supply].tokenId = tokenId;
        tokens[supply].owner = mintTo;
        tokens[supply].cids.push(input[3]);

        supply += 1;
      }
    } else {
      require(tokenId < supply, "Invalid TokenId");
      tokens[tokenId].cids.push(input[3]);
    }

    isNullifierExpired[input[4]] = true;

    emit ZKProof(mintTo, a, b, c, input);
  }
  function pushZKProofs(
    uint[2][] memory a,
    uint[2][2][] memory b,
    uint[2][] memory c,
    uint[5][] memory input
  ) external {
    uint256 length = input.length;
    require(a.length == length && b.length == length && c.length == length, "Invalid length");

    for (uint256 i = 0; i < length; i++)
      pushZKProof(a[i], b[i], c[i], input[i]);
  }

  // Get the metadata of an NFT
  function getNFTMetadata(uint256 _tokenId) external view returns (NFTMetadata memory) {
    require(_exists(_tokenId), "Token ID does not exist");
    return tokens[_tokenId];
  }

  function getMintTo(uint256 number) public pure returns (bytes20) {
    // Shift the uint256 value to the right by 80 bits to get the last 20 bytes
    bytes20 converted = bytes20(uint160(number >> 80));
    return converted;
  }

  function getTokenId(uint256 value) public pure returns (uint256) {
    // Define a mask with the desired bits set to 1
    uint256 mask = uint256(EMPTY_TOKEN_ID);

    // Perform a bitwise AND with the mask to get the last 12 bytes
    uint256 result = value & mask;

    return result;
  }

  function getTokenIdByAddress(address owner) public view returns (uint256) {
    for (uint256 i = 0; i < supply; ++i)
      if (tokens[i].owner == owner) return i;

    return uint256(2 ** 80 - 1);
  }

  /// @notice Get the base64-encoded json metadata for a token
  /// @param tokenId the token id to get the metadata for
  /// @return base64-encoded json metadata object
  function tokenURI(uint256 tokenId) public view override returns (string memory) {
    require(ownerOf(tokenId) != address(0), "No token");

    return createTokenMetadata(name(), tokenId, 0);
  }

  function calcPropertiesJson(uint256 tokenId) internal view override returns (string memory) {
    uint256 len = tokens[tokenId].cids.length;
    uint256 lengthMinusOne = len - 1;

    string memory buffer = '';

    for (uint256 i = 0; i < lengthMinusOne; ) {
      buffer = string.concat(
        buffer,
        stringifyStringAttribute(
          "Credential",
          LibString.toString(tokens[tokenId].cids[i])),
        ","
      );

      // counter increment can not overflow
      ++i;
    }

    return string.concat(
      buffer,
      stringifyStringAttribute(
        "Credential",
        LibString.toString(tokens[tokenId].cids[lengthMinusOne]))
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
