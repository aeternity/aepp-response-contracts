pragma solidity ^0.4.15;

interface ERC20Token {
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
}

contract Response {
  ERC20Token token;
  address owner;
  address backend;
  mapping(address => bool) foundations;

  function Response(ERC20Token _token) public {
    token = _token;
    owner = msg.sender;
  }

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  function setBackend(address _backend) public onlyOwner {
    backend = _backend;
  }

  function setFoundation(address foundation, bool exist) public onlyOwner {
    foundations[foundation] = exist;
  }

  struct HighestSupporter {
    address account;
    uint lastSupportAt;
  }

  struct Question {
    uint twitterUserId;
    string content;
    address author;
    address foundation;
    uint createdAt;
    uint deadlineAt;
    uint tweetId;

    mapping(address => uint) supporterAmount;
    mapping(address => bool) isSupportReverted;
    HighestSupporter[5] highestSupporters;
    uint supporterCount;
    uint amount;
  }

  Question[] public questions;

  function questionCount() public constant returns (uint) {
    return questions.length;
  }

  function supporterAmount(uint questionIdx, address supporterAddress) public constant
  returns (uint) {
    return questions[questionIdx].supporterAmount[supporterAddress];
  }

  function isSupportReverted(uint questionIdx, address supporterAddress) public constant
  returns (bool) {
    return questions[questionIdx].isSupportReverted[supporterAddress];
  }

  function highestSupporter(uint questionIdx, uint supporterIdx) public constant
  returns (address, uint, uint) {
    Question storage question = questions[questionIdx];
    HighestSupporter storage s = question.highestSupporters[supporterIdx];
    return (s.account, s.lastSupportAt, question.supporterAmount[s.account]);
  }

  function receiveApproval(
    address from, uint256 value, address, bytes extraData
  ) public {
    require(address(token) == msg.sender);
    require(token.transferFrom(from, this, value));
    uint padding = 32;
    uint extraDataFirstArgument;
    assembly { extraDataFirstArgument := mload(add(extraData, padding)) }
    Question storage question;

    if (extraData.length > 32) {
      padding += 32;
      string memory content;
      assembly { content := add(extraData, padding) }
      padding += 32 + bytes(content).length + (32 - bytes(content).length % 32) % 32;
      address foundation;
      assembly { foundation := mload(add(extraData, padding)) }
      padding += 32;
      uint deadlineAt;
      assembly { deadlineAt := mload(add(extraData, padding)) }

      require(foundations[foundation]);
      require(now + 1 weeks <= deadlineAt);
      require(now + 1 years >= deadlineAt);
      // todo twitter user id and content is unchecked

      questions.length += 1;
      question = questions[questions.length - 1];
      question.twitterUserId = extraDataFirstArgument;
      question.content = content;
      question.author = from;
      question.foundation = foundation;
      question.createdAt = now;
      question.deadlineAt = deadlineAt;
      question.supporterCount = 1;
      question.amount = value;
      question.supporterAmount[from] = value;
      question.highestSupporters[0] = HighestSupporter({ account: from, lastSupportAt: now });
    } else {
      question = questions[extraDataFirstArgument];
      require(now < question.deadlineAt);
      question.amount += value;
      if (0 == question.supporterAmount[from]) question.supporterCount += 1;
      question.supporterAmount[from] += value;

      HighestSupporter[5] storage supporters = question.highestSupporters;
      mapping(address => uint) amounts = question.supporterAmount;
      if (amounts[supporters[4].account] >= amounts[from] && supporters[4].account != from) {
        return;
      }
      for (uint i = 0; i <= 4 && supporters[i].account != from; i++) {}
      for (; i > 0 && amounts[supporters[i - 1].account] < amounts[from]; i--) {
        if (i < 5) supporters[i] = question.highestSupporters[i - 1];
      }
      supporters[i] = HighestSupporter({ account: from, lastSupportAt: now });
    }
  }

  function answer(uint questionIdx, uint tweetId) public {
    Question storage question = questions[questionIdx];
    require(msg.sender == backend && now < question.deadlineAt);
    assert(token.transfer(question.foundation, question.amount));
    question.tweetId = tweetId;
  }

  function revertSupport(uint questionIdx) public {
    Question storage question = questions[questionIdx];
    require(question.tweetId == 0 && now >= question.deadlineAt &&
      !question.isSupportReverted[msg.sender] && question.supporterAmount[msg.sender] > 0);
    assert(token.transfer(msg.sender, question.supporterAmount[msg.sender]));
    question.isSupportReverted[msg.sender] = true;
  }
}
