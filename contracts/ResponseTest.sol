pragma solidity ^0.4.15;

contract ResponseTest {
  struct HighestSupporter {
    address account;
    uint lastSupportAt;
  }
  mapping(address => uint) public suppAmount;
  HighestSupporter[5] public highestSupp;

  function support1(uint256 value) public {
    suppAmount[msg.sender] += value;

    if (
      suppAmount[highestSupp[4].account] >= suppAmount[msg.sender]
      && highestSupp[4].account != msg.sender
    ) {
      return;
    }
    for (uint i = 0; i <= 4 && highestSupp[i].account != msg.sender; i++) {}
    for (; i > 0 && suppAmount[highestSupp[i - 1].account] < suppAmount[msg.sender]; i--) {
      if (i < 5) highestSupp[i] = highestSupp[i - 1];
    }
    highestSupp[i] = HighestSupporter({ account: msg.sender, lastSupportAt: now });
  }

  
  struct Supporter {
    uint lastSupportAt;
    uint amount;
  }
  mapping(address => Supporter) public supporters;

  function support2(uint256 value) public {
    supporters[msg.sender].amount += value;
    supporters[msg.sender].lastSupportAt = now;
  }
}
