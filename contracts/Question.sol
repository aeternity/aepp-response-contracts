pragma solidity ^0.4.15;

import "./AEToken/AEToken.sol";

contract Question {
  uint public constant version = 1;

  struct HighestDonor {
    address addr;
    uint lastDonatedAt;
  }

  AEToken token;
  address backend;
  string public twitterAccount;
  string public question;
  address public charityAddress;
  uint public deadline;
  string public tweetUrl;
  mapping(address => uint) public donorAmounts;
  mapping(address => bool) public donorRevertDonation;
  HighestDonor[5] public highestDonors;
  uint public donorCount;
  uint256 public donations;
  address public author;

  modifier beforeDeadline() {
    require(now < deadline);
    _;
  }

  function Question(
    AEToken _token, address _backend,
    string _twitterAccount, string _question,
    address _charityAddress, uint _deadline,
    address _author, uint amount
  ) {
    require(bytes(_twitterAccount).length != 0);
    // todo check twitter account more carefully
    require(bytes(_question).length != 0);
    require(now + 1 weeks <= _deadline);

    token = _token;
    backend = _backend;
    twitterAccount = _twitterAccount;
    question = _question;
    charityAddress = _charityAddress;
    deadline = _deadline;
    author = _author;

    donorCount = 1;
    donations = amount;
    donorAmounts[_author] = amount;
    highestDonors[0] = HighestDonor({ addr: _author, lastDonatedAt: now });
  }

  function receiveApproval(address from, uint256 value, address _tokenContract, bytes extraData) beforeDeadline {
    require(address(token) == _tokenContract);
    require(value > 0);
    require(token.transferFrom(from, this, value));

    if (0 == donorAmounts[from]) donorCount += 1;
    donations += value;
    donorAmounts[from] += value;
    updateHighestDonors(from);
  }

  function updateHighestDonors(address donor) internal {
    uint amount = donorAmounts[donor];
    if (donorAmounts[highestDonors[4].addr] >= amount) return;
    for (uint i = 0; i <= 4 && highestDonors[i].addr != donor; i++) {}

    for (; i > 0 && donorAmounts[highestDonors[i - 1].addr] < amount; i--) {
      if (i < 5) {
        highestDonors[i] = highestDonors[i - 1];
      }
    }
    highestDonors[i] = HighestDonor({ addr: donor, lastDonatedAt: now });
  }

  function answer(string _tweetUrl) beforeDeadline {
    require(msg.sender == backend);
    tweetUrl = _tweetUrl;
    assert(token.transfer(charityAddress, donations));
  }

  function revertDonation() {
    require(bytes(tweetUrl).length == 0);
    require(now >= deadline);
    require(donorAmounts[msg.sender] != 0);
    require(!donorRevertDonation[msg.sender]);
    assert(token.transfer(msg.sender, donorAmounts[msg.sender]));
    donorRevertDonation[msg.sender] = true;
  }
}
