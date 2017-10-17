pragma solidity ^0.4.15;

import "./ContractRegistry.sol";
import "./ERC20Token.sol";
import "./Question.sol";

contract QuestionCreator {
  ContractRegistry registry;
  ERC20Interface token;

  function QuestionCreator(ContractRegistry _registry, ERC20Interface _token) {
    registry = _registry;
    token = _token;
  }

  function create(string _question, string _twitterAccount, uint _deadline) returns (address) {
    address newQuestion = new Question(token, _question, _twitterAccount, _deadline);
    registry.add(newQuestion);
    return newQuestion;
  }
}
