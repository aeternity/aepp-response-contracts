pragma solidity 0.4.18;

contract Store {
  mapping(bytes32 => uint256) private uIntStore;
  mapping(bytes32 => string) private stringStore;
  mapping(bytes32 => address) private addressStore;
  mapping(bytes32 => bytes) private bytesStore;
  mapping(bytes32 => bytes32) private bytes32Store;
  mapping(bytes32 => bool) private boolStore;
  mapping(bytes32 => int256) private intStore;

  bytes32 constant STORAGE = 'storage';
  bytes32 constant HAS_WRITE_ACCESS = 'hasWriteAccess';

  function Store() public {
    boolStore[keccak256(STORAGE, HAS_WRITE_ACCESS, msg.sender)] = true;
  }

  modifier requireWriteAccess() {
    require(boolStore[keccak256(STORAGE, HAS_WRITE_ACCESS, msg.sender)]);
    _;
  }

  function setWriteAccess(address account, bool writeAccess) requireWriteAccess external {
    boolStore[keccak256(STORAGE, HAS_WRITE_ACCESS, account)] = writeAccess;
  }


  function getAddress(bytes32 key) external view returns (address) {
    return addressStore[key];
  }

  function getUint(bytes32 key) external view returns (uint) {
    return uIntStore[key];
  }

  function getString(bytes32 key) external view returns (string) {
    return stringStore[key];
  }

  function getBytes(bytes32 key) external view returns (bytes) {
    return bytesStore[key];
  }

  function getBytes32(bytes32 key) external view returns (bytes32) {
    return bytes32Store[key];
  }

  function getBool(bytes32 key) external view returns (bool) {
    return boolStore[key];
  }

  function getInt(bytes32 key) external view returns (int) {
    return intStore[key];
  }


  function setAddress(bytes32 key, address value) requireWriteAccess external {
    addressStore[key] = value;
  }

  function setUint(bytes32 key, uint value) requireWriteAccess external {
    uIntStore[key] = value;
  }

  function setString(bytes32 key, string value) requireWriteAccess external {
    stringStore[key] = value;
  }

  function setBytes(bytes32 key, bytes value) requireWriteAccess external {
    bytesStore[key] = value;
  }

  function setBytes32(bytes32 key, bytes32 value) requireWriteAccess external {
    bytes32Store[key] = value;
  }

  function setBool(bytes32 key, bool value) requireWriteAccess external {
    boolStore[key] = value;
  }

  function setInt(bytes32 key, int value) requireWriteAccess external {
    intStore[key] = value;
  }


  function deleteAddress(bytes32 key) requireWriteAccess external {
    delete addressStore[key];
  }

  function deleteUint(bytes32 key) requireWriteAccess external {
    delete uIntStore[key];
  }

  function deleteString(bytes32 key) requireWriteAccess external {
    delete stringStore[key];
  }

  function deleteBytes(bytes32 key) requireWriteAccess external {
    delete bytesStore[key];
  }

  function deleteBytes32(bytes32 key) requireWriteAccess external {
    delete bytes32Store[key];
  }

  function deleteBool(bytes32 key) requireWriteAccess external {
    delete boolStore[key];
  }

  function deleteInt(bytes32 key) requireWriteAccess external {
    delete intStore[key];
  }
}
