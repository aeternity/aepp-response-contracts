pragma solidity 0.4.18;

import './ResponseStore.sol';

interface ERC20Token {
  function transfer(address to, uint256 value) public returns (bool success);
  function transferFrom(address from, address to, uint256 value) public returns (bool success);
}

contract Response {
  Store s;
  using ResponseStore for Store;
  ERC20Token token;
  address owner;

  bytes32 constant BACKEND = 'backend';
  bytes32 constant BACKEND_FEE = 'backendFee';
  bytes32 constant QUESTION_COUNT = 'questionCount';
  bytes32 constant TWITTER_USER_ID = 'twitterUserId';
  bytes32 constant CONTENT = 'content';
  bytes32 constant AUTHOR = 'author';
  bytes32 constant FOUNDATION = 'foundation';
  bytes32 constant CREATED_AT = 'createdAt';
  bytes32 constant QUESTION_TWEET_ID = 'questionTweetId';
  bytes32 constant ANSWER_TWEET_ID = 'answerTweetId';
  bytes32 constant SUPPORTER_COUNT = 'supporterCount';
  bytes32 constant AMOUNT = 'amount';
  bytes32 constant HIGHEST_LOWEST_SUPPORTER_IDX = 'highestLowestSupporterIdx';
  bytes32 constant SUPPORTER_AMOUNT = 'supporterAmount';
  bytes32 constant SUPPORTER_REVERTED_AT = 'supportRevertedAt';
  bytes32 constant HIGHEST_SUPPORTERS = 'highestSupporters';
  bytes32 constant ACCOUNT = 'account';
  bytes32 constant LAST_SUPPORT_AT = 'lastSupportAt';

  function Response(Store store, ERC20Token _token) public {
    s = store;
    token = _token;
    owner = msg.sender;
  }

  modifier onlyBy(address account) {
    require(msg.sender == account);
    _;
  }

  enum DeadlineStates { Before, After }

  modifier deadline(DeadlineStates state, uint qIdx) {
    uint deadlineAt = s.qUint(qIdx, CREATED_AT) + 30 days;
    require(state == DeadlineStates.Before && now < deadlineAt ||
      state == DeadlineStates.After && now >= deadlineAt);
    _;
  }

  modifier unanswered(uint qIdx) {
    require(s.qUint(qIdx, ANSWER_TWEET_ID) == 0);
    _;
  }

  function setBackend(address backend) public onlyBy(owner) {
    s.setR(BACKEND, backend);
  }

  function backendFee() public constant returns(uint) {
    return s.rUint(BACKEND_FEE);
  }

  function setBackendFee(uint _backendFee) public onlyBy(s.rAddress(BACKEND)) {
    s.setR(BACKEND_FEE, _backendFee);
  }

  function setFoundation(address foundation, bool exist) public onlyBy(owner) {
    s.setR(FOUNDATION, foundation, exist);
  }

  function questionCount() public constant returns (uint) {
    return s.rUint(QUESTION_COUNT);
  }

  function questions(uint qIdx) public constant returns (
    uint twitterUserId,
    bytes32 content,
    address author,
    address foundation,
    uint createdAt,
    uint questionTweetId,
    uint answerTweetId,
    uint supporterCount,
    uint amount
  ) {
    twitterUserId = s.qUint(qIdx, TWITTER_USER_ID);
    content = s.qBytes32(qIdx, CONTENT);
    author = s.qAddress(qIdx, AUTHOR);
    foundation = s.qAddress(qIdx, FOUNDATION);
    createdAt = s.qUint(qIdx, CREATED_AT);
    questionTweetId = s.qUint(qIdx, QUESTION_TWEET_ID);
    answerTweetId = s.qUint(qIdx, ANSWER_TWEET_ID);
    supporterCount = s.qUint(qIdx, SUPPORTER_COUNT);
    amount = s.qUint(qIdx, AMOUNT);
  }

  function supporterAmount(uint qIdx, address supporterAddress) public constant
  returns (uint) {
    return s.qUint(qIdx, SUPPORTER_AMOUNT, supporterAddress);
  }

  function supportRevertedAt(uint qIdx, address supporterAddress) public constant
  returns (uint) {
    return s.qUint(qIdx, SUPPORTER_REVERTED_AT, supporterAddress);
  }

  function highestSupporter(uint qIdx, uint supporterIdx) public constant
  returns (address account, uint lastSupportAt, uint amount) {
    account = s.qAddress(qIdx, HIGHEST_SUPPORTERS, supporterIdx, ACCOUNT);
    lastSupportAt = s.qUint(qIdx, HIGHEST_SUPPORTERS, supporterIdx, LAST_SUPPORT_AT);
    amount = s.qUint(qIdx, SUPPORTER_AMOUNT, account);
  }

  function createQuestion(
    uint twitterUserId, bytes32 content, address foundation, uint amount
  ) payable public {
    require(msg.value == s.rUint(BACKEND_FEE));
    require(token.transferFrom(msg.sender, this, amount));
    require(s.rBool(FOUNDATION, foundation));
    // todo twitter user id and content is unchecked

    s.rAddress(BACKEND).transfer(s.rUint(BACKEND_FEE));
    uint qIdx = s.rUint(QUESTION_COUNT);
    s.setQ(qIdx, CONTENT, content);
    s.setQ(qIdx, AUTHOR, msg.sender);
    s.setQ(qIdx, FOUNDATION, foundation);
    s.setQ(qIdx, AMOUNT, amount);
    s.setQ(qIdx, TWITTER_USER_ID, twitterUserId);
    s.setQ(qIdx, CREATED_AT, now);
    s.setQ(qIdx, SUPPORTER_COUNT, uint(1));
    s.setQ(qIdx, HIGHEST_LOWEST_SUPPORTER_IDX, uint(1));
    s.setQ(qIdx, SUPPORTER_AMOUNT, msg.sender, amount);
    s.setQ(qIdx, HIGHEST_SUPPORTERS, uint(0), ACCOUNT, msg.sender);
    s.setQ(qIdx, HIGHEST_SUPPORTERS, uint(0), LAST_SUPPORT_AT, now);
    s.setR(QUESTION_COUNT, qIdx + 1);
  }

  function updateHighestLowestSupporterIdx(uint qIdx) internal {
    uint sIdx;
    for (uint i = 1; i <= 4; i++) {
      if (s.qUint(qIdx, SUPPORTER_AMOUNT, s.qAddress(qIdx, HIGHEST_SUPPORTERS, i, ACCOUNT))
        < s.qUint(qIdx, SUPPORTER_AMOUNT, s.qAddress(qIdx, HIGHEST_SUPPORTERS, sIdx, ACCOUNT))) {
        sIdx = i;
      }
    }
    s.setQ(qIdx, HIGHEST_LOWEST_SUPPORTER_IDX, sIdx);
  }

  function receiveApproval(address from, uint256 value, address, bytes extraData) public {
    require(address(token) == msg.sender);
    require(token.transferFrom(from, this, value));
    uint qIdx;
    assembly { qIdx := mload(add(extraData, 32)) }
    require(now < s.qUint(qIdx, CREATED_AT) + 30 days);
    require(0 == s.qUint(qIdx, ANSWER_TWEET_ID));

    s.incQ(qIdx, AMOUNT, value);
    uint amountFrom = s.qUint(qIdx, SUPPORTER_AMOUNT, from);
    if (0 == amountFrom) s.incQ(qIdx, SUPPORTER_COUNT, 1);
    amountFrom += value;
    s.setQ(qIdx, SUPPORTER_AMOUNT, from, amountFrom);

    uint lowestIdx = s.qUint(qIdx, HIGHEST_LOWEST_SUPPORTER_IDX);
    if (s.qUint(qIdx, SUPPORTER_AMOUNT, s.qAddress(qIdx, HIGHEST_SUPPORTERS, lowestIdx, ACCOUNT))
      < amountFrom) {
      for (uint i = 0; i <= 4; i++)
        if (s.qAddress(qIdx, HIGHEST_SUPPORTERS, i, ACCOUNT) == from) {
          if (i == lowestIdx) updateHighestLowestSupporterIdx(qIdx);
          return;
        }
      s.setQ(qIdx, HIGHEST_SUPPORTERS, lowestIdx, ACCOUNT, from);
      s.setQ(qIdx, HIGHEST_SUPPORTERS, lowestIdx, LAST_SUPPORT_AT, now);
      updateHighestLowestSupporterIdx(qIdx);
    }
  }

  function setQuestionTweetId(uint qIdx, uint questionTweetId)
  public onlyBy(s.rAddress(BACKEND)) deadline(DeadlineStates.Before, qIdx) {
    require(0 == s.qUint(qIdx, QUESTION_TWEET_ID));
    s.setQ(qIdx, QUESTION_TWEET_ID, questionTweetId);
  }

  function setAnswerTweetId(uint qIdx, uint answerTweetId)
  public onlyBy(s.rAddress(BACKEND)) deadline(DeadlineStates.Before, qIdx) unanswered(qIdx) {
    assert(token.transfer(s.qAddress(qIdx, FOUNDATION), s.qUint(qIdx, AMOUNT)));
    s.setQ(qIdx, ANSWER_TWEET_ID, answerTweetId);
  }

  function revertSupport(uint qIdx)
  public deadline(DeadlineStates.After, qIdx) unanswered(qIdx) {
    uint amount = s.qUint(qIdx, SUPPORTER_AMOUNT, msg.sender);
    require(amount > 0 && s.qUint(qIdx, SUPPORTER_REVERTED_AT, msg.sender) == 0);
    assert(token.transfer(msg.sender, amount));
    s.setQ(qIdx, SUPPORTER_REVERTED_AT, msg.sender, now);
  }
}
