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

  enum DeadlineStates { Before, After }

  modifier deadline(DeadlineStates state, uint questionIdx) {
    uint deadlineAt = questions[questionIdx].createdAt + 30 days;
    require(state == DeadlineStates.Before && now < deadlineAt ||
      state == DeadlineStates.After && now >= deadlineAt);
    _;
  }

  modifier unanswered(uint questionIdx) {
    require(questions[questionIdx].answerTweetId == 0);
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
    bytes32 content;
    address author;
    address foundation;
    uint createdAt;
    uint questionTweetId;
    uint answerTweetId;

    mapping(address => uint) supporterAmount;
    mapping(address => uint) supportRevertedAt;
    HighestSupporter[5] highestSupporters;
    uint highestLowestSupporterIdx;
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

  function supportRevertedAt(uint questionIdx, address supporterAddress) public constant
  returns (uint) {
    return questions[questionIdx].supportRevertedAt[supporterAddress];
  }

  function highestSupporter(uint questionIdx, uint supporterIdx) public constant
  returns (address, uint, uint) {
    Question storage question = questions[questionIdx];
    HighestSupporter storage s = question.highestSupporters[supporterIdx];
    return (s.account, s.lastSupportAt, question.supporterAmount[s.account]);
  }

  function createQuestion(
    uint twitterUserId, bytes32 content, address foundation, uint amount
  ) payable public {
    require(msg.value == backendFee);
    require(token.transferFrom(msg.sender, this, amount));
    require(foundations[foundation]);
    // todo twitter user id and content is unchecked

    backend.transfer(backendFee);
    questions.length += 1;
    Question storage question = questions[questions.length - 1];
    question.twitterUserId = twitterUserId;
    question.content = content;
    question.author = msg.sender;
    question.foundation = foundation;
    question.createdAt = now;
    question.supporterCount = 1;
    question.amount = amount;
    question.supporterAmount[msg.sender] = amount;
    question.highestSupporters[0] = HighestSupporter({ account: msg.sender, lastSupportAt: now });
    question.highestLowestSupporterIdx = 1;
  }

  function updateHighestLowestSupporterIdx(uint qIdx) internal {
    mapping(address => uint) amounts = questions[qIdx].supporterAmount;
    HighestSupporter[5] storage supporters = questions[qIdx].highestSupporters;
    uint sIdx;
    for (uint i = 1; i <= 4; i++) {
      if (amounts[supporters[i].account] < amounts[supporters[sIdx].account]) sIdx = i;
    }
    questions[qIdx].highestLowestSupporterIdx = sIdx;
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
    require(now < question.createdAt + 30 days);
    require(0 == question.answerTweetId);

    question.amount += value;
    mapping(address => uint) amounts = question.supporterAmount;
    if (0 == amounts[from]) question.supporterCount += 1;
    amounts[from] += value;

    HighestSupporter[5] storage supporters = question.highestSupporters;
    uint lowestIdx = question.highestLowestSupporterIdx;
    if (amounts[from] > amounts[supporters[lowestIdx].account]) {
      for (uint i = 0; i <= 4; i++)
        if (supporters[i].account == from) {
          if (i == lowestIdx) updateHighestLowestSupporterIdx(questionIdx);
          return;
        }
      supporters[lowestIdx] = HighestSupporter({ account: from, lastSupportAt: now });
      updateHighestLowestSupporterIdx(questionIdx);
    }
  }

  function setQuestionTweetId(uint questionIdx, uint questionTweetId)
  public onlyBy(backend) deadline(DeadlineStates.Before, questionIdx) {
    Question storage question = questions[questionIdx];
    require(0 == question.questionTweetId);
    question.questionTweetId = questionTweetId;
  }

  function setAnswerTweetId(uint questionIdx, uint answerTweetId)
  public onlyBy(backend) deadline(DeadlineStates.Before, questionIdx) unanswered(questionIdx) {
    Question storage question = questions[questionIdx];
    assert(token.transfer(question.foundation, question.amount));
    question.answerTweetId = answerTweetId;
  }

  function revertSupport(uint questionIdx)
  public deadline(DeadlineStates.After, questionIdx) unanswered(questionIdx) {
    Question storage question = questions[questionIdx];
    uint amount = question.supporterAmount[msg.sender];
    require(question.supportRevertedAt[msg.sender] == 0 && amount > 0);
    assert(token.transfer(msg.sender, amount));
    question.supportRevertedAt[msg.sender] = now;
  }
}
