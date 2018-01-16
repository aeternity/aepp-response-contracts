pragma solidity 0.4.18;

import './Store.sol';

library ResponseStore {
  bytes32 constant R = 'response';
  bytes32 constant Q = 'question';

  function rAddress(Store s, bytes32 n) internal view returns(address) {
    return s.getAddress(keccak256(R, n));
  }

  function rUint(Store s, bytes32 n) internal view returns(uint) {
    return s.getUint(keccak256(R, n));
  }

  function rBool(Store s, bytes32 n, address a) internal view returns(bool) {
    return s.getBool(keccak256(R, n, a));
  }

  function setR(Store s, bytes32 n, address v) internal {
    s.setAddress(keccak256(R, n), v);
  }

  function setR(Store s, bytes32 n, uint v) internal {
    s.setUint(keccak256(R, n), v);
  }

  function setR(Store s, bytes32 n, address a, bool v) internal {
    s.setBool(keccak256(R, n, a), v);
  }


  function qAddress(Store s, uint qIdx, bytes32 n) internal view returns(address) {
    return s.getAddress(keccak256(R, Q, qIdx, n));
  }

  function qAddress(Store s, uint qIdx, bytes32 n, uint u, bytes32 st) internal view returns(address) {
    return s.getAddress(keccak256(R, Q, qIdx, n, u, st));
  }

  function qUint(Store s, uint qIdx, bytes32 n) internal view returns(uint) {
    return s.getUint(keccak256(R, Q, qIdx, n));
  }

  function qUint(Store s, uint qIdx, bytes32 n, address a) internal view returns(uint) {
    return s.getUint(keccak256(R, Q, qIdx, n, a));
  }

  function qUint(Store s, uint qIdx, bytes32 n, uint u, bytes32 st) internal view returns(uint) {
    return s.getUint(keccak256(R, Q, qIdx, n, u, st));
  }

  function qBytes32(Store s, uint qIdx, bytes32 n) internal view returns(bytes32) {
    return s.getBytes32(keccak256(R, Q, qIdx, n));
  }

  function setQ(Store s, uint qIdx, bytes32 n, address v) internal {
    s.setAddress(keccak256(R, Q, qIdx, n), v);
  }

  function setQ(Store s, uint qIdx, bytes32 n, uint u, bytes32 st, address v) internal {
    s.setAddress(keccak256(R, Q, qIdx, n, u, st), v);
  }

  function setQ(Store s, uint qIdx, bytes32 n, uint v) internal {
    s.setUint(keccak256(R, Q, qIdx, n), v);
  }

  function setQ(Store s, uint qIdx, bytes32 n, uint u, bytes32 st, uint v) internal {
    s.setUint(keccak256(R, Q, qIdx, n, u, st), v);
  }

  function setQ(Store s, uint qIdx, bytes32 n, address a, uint v) internal {
    return s.setUint(keccak256(R, Q, qIdx, n, a), v);
  }

  function setQ(Store s, uint qIdx, bytes32 n, bytes32 v) internal {
    s.setBytes32(keccak256(R, Q, qIdx, n), v);
  }

  function incQ(Store s, uint qIdx, bytes32 n, uint v) internal {
    s.setUint(keccak256(R, Q, qIdx, n), s.getUint(keccak256(R, Q, qIdx, n)) + v);
  }
}
