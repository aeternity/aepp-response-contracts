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


  function support3(uint256 value) public {
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


  uint minIdx;

  function updateMinIdx() internal {
    uint sIdx;
    for (uint i = 1; i <= 4; i++) {
      if (suppAmount[highestSupp[i].account] < suppAmount[highestSupp[sIdx].account]) sIdx = i;
    }
    minIdx = sIdx;
  }

  function support4(uint256 value) public {
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

  function support5(uint256 value) public {
    suppAmount[msg.sender] += value;

    if (suppAmount[msg.sender] <= suppAmount[highestSupp[minIdx].account]) return;
    if (suppAmount[msg.sender] - value > suppAmount[highestSupp[minIdx].account]) return;

    if (suppAmount[msg.sender] - value == suppAmount[highestSupp[minIdx].account]) {
      if (highestSupp[minIdx].account == msg.sender) {
        updateMinIdx();
        return;
      }
      for (uint i = 0; i <= 4; i++)
        if (highestSupp[i].account == msg.sender) return;
    }

    highestSupp[minIdx] = HighestSupporter({ account: msg.sender, lastSupportAt: now });
    updateMinIdx();
  }
}
