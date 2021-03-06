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
  bytes32 constant CONTENT = 'content';
  bytes32 constant AUTHOR = 'author';
  bytes32 constant FOUNDATION = 'foundation';
  bytes32 constant PACKED_STATE = 'packedState';
  bytes32 constant AMOUNT = 'amount';
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
    uint deadlineAt = questionState(qIdx).createdAt + 30 days;
    require(state == DeadlineStates.Before && now < deadlineAt ||
      state == DeadlineStates.After && now >= deadlineAt);
    _;
  }

  modifier unanswered(uint qIdx) {
    require(!questionState(qIdx).answered);
    _;
  }

  function setBackend(address backend) external onlyBy(owner) {
    s.setR(BACKEND, backend);
  }

  function backendFee() external view returns(uint) {
    return s.rUint(BACKEND_FEE);
  }

  function setBackendFee(uint _backendFee) external onlyBy(s.rAddress(BACKEND)) {
    s.setR(BACKEND_FEE, _backendFee);
  }

  function setFoundation(address foundation, bool exist) external onlyBy(owner) {
    s.setR(FOUNDATION, foundation, exist);
  }

  function questionCount() external view returns (uint) {
    return s.rUint(QUESTION_COUNT);
  }

  struct QuestionState {
    uint64 twitterUserId;
    uint64 tweetId;
    uint32 createdAt;
    uint32 supporterCount;
    bool answered;
    uint8 highestLowestSupporterIdx;
  }

  function questionState(uint qIdx) internal view returns (QuestionState t) {
    uint packedState = s.qUint(qIdx, PACKED_STATE);
    t.twitterUserId = uint64(packedState);
    packedState >>= 64;
    t.tweetId = uint64(packedState);
    packedState >>= 64;
    t.createdAt = uint32(packedState);
    packedState >>= 32;
    t.supporterCount = uint32(packedState);
    packedState >>= 32;
    t.answered = packedState & 1 != 0;
    packedState >>= 1;
    t.highestLowestSupporterIdx = uint8(packedState);
  }

  function setQuestionState(uint qIdx, QuestionState t) internal {
    uint packedState = t.highestLowestSupporterIdx;
    packedState <<= 1;
    packedState |= t.answered ? 1 : 0;
    packedState <<= 32;
    packedState |= t.supporterCount;
    packedState <<= 32;
    packedState |= t.createdAt;
    packedState <<= 64;
    packedState |= t.tweetId;
    packedState <<= 64;
    packedState |= t.twitterUserId;
    s.setQ(qIdx, PACKED_STATE, packedState);
  }

  function questions(uint qIdx) external view returns (
    uint twitterUserId,
    bytes32 content,
    address author,
    address foundation,
    uint createdAt,
    uint tweetId,
    bool answered,
    uint supporterCount,
    uint amount
  ) {
    QuestionState memory qs = questionState(qIdx);
    twitterUserId = qs.twitterUserId;
    content = s.qBytes32(qIdx, CONTENT);
    author = s.qAddress(qIdx, AUTHOR);
    foundation = s.qAddress(qIdx, FOUNDATION);
    createdAt = qs.createdAt;
    tweetId = qs.tweetId;
    answered = qs.answered;
    supporterCount = qs.supporterCount;
    amount = s.qUint(qIdx, AMOUNT);
  }

  function supporterAmount(uint qIdx, address supporterAddress) external view
  returns (uint) {
    return s.qUint(qIdx, SUPPORTER_AMOUNT, supporterAddress);
  }

  function supportRevertedAt(uint qIdx, address supporterAddress) external view
  returns (uint) {
    return s.qUint(qIdx, SUPPORTER_REVERTED_AT, supporterAddress);
  }

  function highestSupporter(uint qIdx, uint supporterIdx) external view
  returns (address account, uint lastSupportAt, uint amount) {
    account = s.qAddress(qIdx, HIGHEST_SUPPORTERS, supporterIdx, ACCOUNT);
    lastSupportAt = s.qUint(qIdx, HIGHEST_SUPPORTERS, supporterIdx, LAST_SUPPORT_AT);
    amount = s.qUint(qIdx, SUPPORTER_AMOUNT, account);
  }

  function createQuestion(
    uint64 twitterUserId, bytes32 content, address foundation, uint amount
  ) payable external {
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
    QuestionState memory qs;
    qs.twitterUserId = twitterUserId;
    qs.createdAt = uint32(now);
    qs.supporterCount = 1;
    qs.highestLowestSupporterIdx = 1;
    setQuestionState(qIdx, qs);
    s.setQ(qIdx, SUPPORTER_AMOUNT, msg.sender, amount);
    s.setQ(qIdx, HIGHEST_SUPPORTERS, uint(0), ACCOUNT, msg.sender);
    s.setQ(qIdx, HIGHEST_SUPPORTERS, uint(0), LAST_SUPPORT_AT, now);
    s.setR(QUESTION_COUNT, qIdx + 1);
  }

  function updateHighestLowestSupporterIdx(uint qIdx) internal {
    uint8 sIdx;
    for (uint8 i = 1; i <= 4; i++) {
      if (s.qUint(qIdx, SUPPORTER_AMOUNT, s.qAddress(qIdx, HIGHEST_SUPPORTERS, i, ACCOUNT))
        < s.qUint(qIdx, SUPPORTER_AMOUNT, s.qAddress(qIdx, HIGHEST_SUPPORTERS, sIdx, ACCOUNT))) {
        sIdx = i;
      }
    }
    QuestionState memory qs = questionState(qIdx);
    qs.highestLowestSupporterIdx = sIdx;
    setQuestionState(qIdx, qs);
  }

  function receiveApproval(address from, uint256 value, address, bytes extraData) public {
    require(address(token) == msg.sender);
    require(token.transferFrom(from, this, value));
    uint qIdx;
    assembly { qIdx := mload(add(extraData, 32)) }
    QuestionState memory qs = questionState(qIdx);
    require(now < qs.createdAt + 30 days);
    require(!qs.answered);

    s.incQ(qIdx, AMOUNT, value);
    uint amountFrom = s.qUint(qIdx, SUPPORTER_AMOUNT, from);
    if (0 == amountFrom) {
      qs.supporterCount += 1;
      setQuestionState(qIdx, qs);
    }
    amountFrom += value;
    s.setQ(qIdx, SUPPORTER_AMOUNT, from, amountFrom);

    uint lowestIdx = qs.highestLowestSupporterIdx;
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

  function setQuestionTweetId(uint qIdx, uint64 questionTweetId)
  external onlyBy(s.rAddress(BACKEND)) deadline(DeadlineStates.Before, qIdx) {
    QuestionState memory qs = questionState(qIdx);
    require(!qs.answered && 0 == qs.tweetId);
    qs.tweetId = questionTweetId;
    setQuestionState(qIdx, qs);
  }

  function setAnswerTweetId(uint qIdx, uint64 answerTweetId)
  external onlyBy(s.rAddress(BACKEND)) deadline(DeadlineStates.Before, qIdx) unanswered(qIdx) {
    assert(token.transfer(s.qAddress(qIdx, FOUNDATION), s.qUint(qIdx, AMOUNT)));
    QuestionState memory qs = questionState(qIdx);
    qs.tweetId = answerTweetId;
    qs.answered = true;
    setQuestionState(qIdx, qs);
  }

  function revertSupport(uint qIdx)
  external deadline(DeadlineStates.After, qIdx) unanswered(qIdx) {
    uint amount = s.qUint(qIdx, SUPPORTER_AMOUNT, msg.sender);
    require(amount > 0 && s.qUint(qIdx, SUPPORTER_REVERTED_AT, msg.sender) == 0);
    assert(token.transfer(msg.sender, amount));
    s.setQ(qIdx, SUPPORTER_REVERTED_AT, msg.sender, now);
  }
}
