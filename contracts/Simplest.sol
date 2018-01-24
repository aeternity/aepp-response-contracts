pragma solidity ^0.4.15;

contract Simplest {
  struct Supporter {
    uint lastSupportAt;
    uint amount;
  }
  mapping(address => Supporter) public supporters;

  function support(uint256 value) public {
    supporters[msg.sender].amount += value;
    supporters[msg.sender].lastSupportAt = now;
  }
}
