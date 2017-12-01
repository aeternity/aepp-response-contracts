pragma solidity ^0.4.15;

import "./ContractRegistry.sol";
import "./AEToken/AEToken.sol";
import "./Question.sol";

contract QuestionCreator {
  ContractRegistry registry;
  AEToken token;
  address backend;
  mapping(address => bool) charities;

  function QuestionCreator(ContractRegistry _registry, AEToken _token, address _backend) {
    registry = _registry;
    token = _token;
    backend = _backend;

    charities[0xfA491DF8780761853D127A9f7b2772D688A0E3B5] = true;
    charities[0x45992982736870Fe45c41049C5F785d4E4cc38Ec] = true;
  }

  function receiveApproval(address from, uint256 value, address _tokenContract, bytes extraData) {
    require(address(token) == _tokenContract);
    require(address(token) == msg.sender);
    require(value > 0);

    uint padding = 32;

    string memory twitterAccount;
    assembly { twitterAccount := add(extraData, padding) }
    padding += 32;
    padding += bytes(twitterAccount).length + (32 - bytes(twitterAccount).length % 32) % 32;

    string memory question;
    assembly { question := add(extraData, padding) }
    padding += 32;
    padding += bytes(question).length + (32 - bytes(question).length % 32) % 32;

    address charity;
    assembly { charity := mload(add(extraData, padding)) }
    padding += 32;

    uint256 deadline;
    assembly { deadline := mload(add(extraData, padding)) }

    require(charities[charity]);
    Question newQuestion = new Question(
      token, backend, twitterAccount, question, charity, deadline, from, value);
    require(token.transferFrom(from, newQuestion, value));
    registry.add(newQuestion);
  }
}
