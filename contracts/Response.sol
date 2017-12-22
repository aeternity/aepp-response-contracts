pragma solidity ^0.4.15;

interface ERC20Token {
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
}

contract Response {
  ERC20Token token;
  address owner;
  address backend;
  uint public backendFee;
  mapping(address => bool) foundations;

  function Response(ERC20Token _token) public {
    token = _token;
    owner = msg.sender;
  }

  modifier onlyBy(address account) {
    require(msg.sender == account);
    _;
  }

  function setBackend(address _backend) public onlyBy(owner) {
    backend = _backend;
  }

  function setBackendFee(uint _backendFee) public onlyBy(backend) {
    backendFee = _backendFee;
  }

  function setFoundation(address foundation, bool exist) public onlyBy(owner) {
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

  function createQuestion(
    uint twitterUserId, string content, address foundation, uint deadlineAt, uint amount
  ) payable public {
    require(msg.value == backendFee);
    require(token.transferFrom(msg.sender, this, amount));
    require(foundations[foundation]);
    require(now + 1 weeks <= deadlineAt);
    require(now + 1 years >= deadlineAt);
    // todo twitter user id and content is unchecked

    backend.transfer(backendFee);
    questions.length += 1;
    Question storage question = questions[questions.length - 1];
    question.twitterUserId = twitterUserId;
    question.content = content;
    question.author = msg.sender;
    question.foundation = foundation;
    question.createdAt = now;
    question.deadlineAt = deadlineAt;
    question.supporterCount = 1;
    question.amount = amount;
    question.supporterAmount[msg.sender] = amount;
    question.highestSupporters[0] = HighestSupporter({ account: msg.sender, lastSupportAt: now });
  }

  function receiveApproval(
    address from, uint256 value, address, bytes extraData
  ) public {
    require(address(token) == msg.sender);
    require(token.transferFrom(from, this, value));
    uint questionIdx;
    assembly { questionIdx := mload(add(extraData, 32)) }
    Question storage question = questions[questionIdx];
    require(question.createdAt != 0);
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

  function answer(uint questionIdx, uint tweetId) public onlyBy(backend) {
    Question storage question = questions[questionIdx];
    require(now < question.deadlineAt);
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
