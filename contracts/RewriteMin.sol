pragma solidity ^0.4.15;

contract RewriteMin {
  struct HighestSupporter {
    address account;
    uint lastSupportAt;
  }
  mapping(address => uint) public suppAmount;
  HighestSupporter[5] public highestSupp;

  function support(uint256 value) public {
    suppAmount[msg.sender] += value;

    uint sIdx;
    for (uint i = 0; i <= 4; i++) {
      if (highestSupp[i].account == msg.sender) return;
      if (suppAmount[highestSupp[i].account] < suppAmount[highestSupp[sIdx].account]) sIdx = i;
    }
    if (suppAmount[highestSupp[sIdx].account] < suppAmount[msg.sender]) {
      highestSupp[sIdx] = HighestSupporter({ account: msg.sender, lastSupportAt: now });
    }
  }
}
