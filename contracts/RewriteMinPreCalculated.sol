pragma solidity ^0.4.15;

contract RewriteMinPreCalculated {
  struct HighestSupporter {
    address account;
    uint lastSupportAt;
  }
  mapping(address => uint) public suppAmount;
  HighestSupporter[5] public highestSupp;
  uint minIdx;

  function updateMinIdx() internal {
    uint sIdx;
    for (uint i = 1; i <= 4; i++) {
      if (suppAmount[highestSupp[i].account] < suppAmount[highestSupp[sIdx].account]) sIdx = i;
    }
    minIdx = sIdx;
  }

  function support(uint256 value) public {
    suppAmount[msg.sender] += value;

    if (suppAmount[msg.sender] > suppAmount[highestSupp[minIdx].account]) {
      for (uint i = 0; i <= 4; i++)
        if (highestSupp[i].account == msg.sender) {
          if (i == minIdx) updateMinIdx();
          return;
        }
      highestSupp[minIdx] = HighestSupporter({ account: msg.sender, lastSupportAt: now });
      updateMinIdx();
    }
  }
}
