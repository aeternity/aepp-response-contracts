pragma solidity ^0.4.15;

contract ResponseList {
  struct Node {
    address account;
    uint lastSupportAt;
    uint next;
  }
  mapping(address => uint) public amount;
  Node[] public nodes;
  uint256 constant UINT256_MAX = ~uint256(0);

  function ResponseList() public {
    nodes.length = 1;
    nodes[0].account = address(UINT256_MAX);
    nodes[0].next = UINT256_MAX;
    amount[nodes[0].account] = UINT256_MAX;
  }

  function support3(uint256 value) public {
    amount[msg.sender] += value;

    uint _p;
    uint p;
    while (nodes[p].next != UINT256_MAX && nodes[p].account != msg.sender) {
      _p = p;
      p = nodes[p].next;
    }
    if (nodes[p].account == msg.sender || amount[nodes[p].account] < amount[msg.sender]) {
      nodes[_p].next = nodes[p].next;
    } else if (nodes.length < 5) p = nodes.length += 1;
    else return;
    nodes[p].account = msg.sender;
    nodes[p].lastSupportAt = now;

    uint p2;
    while (amount[nodes[nodes[p2].next].account] >= amount[msg.sender]) {
      p2 = nodes[p2].next;
    }
    nodes[p].next = nodes[p2].next;
    nodes[p2].next = p;
  }
}
