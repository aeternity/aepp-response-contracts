pragma solidity ^0.4.15;

import "./ContractRegistry.sol";
import "./AEToken/AEToken.sol";
import "./Question.sol";

contract QuestionCreator {
  ContractRegistry registry;
  AEToken token;
  address backend;
  mapping(uint => address) charityAddresses;

  function QuestionCreator(ContractRegistry _registry, AEToken _token, address _backend) {
    registry = _registry;
    token = _token;
    backend = _backend;

    charityAddresses[1] = 0xfA491DF8780761853D127A9f7b2772D688A0E3B5;
    charityAddresses[2] = 0x45992982736870Fe45c41049C5F785d4E4cc38Ec;
    charityAddresses[3] = 0xfA491DF8780761853D127A9f7b2772D688A0E3B5;
    charityAddresses[4] = 0x45992982736870Fe45c41049C5F785d4E4cc38Ec;
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

    uint256 charityId;
    assembly { charityId := mload(add(extraData, padding)) }
    padding += 32;

    uint256 deadline;
    assembly { deadline := mload(add(extraData, padding)) }

    require(charityAddresses[charityId] != 0);
    Question newQuestion = new Question(
      token, backend, twitterAccount, question,
      charityAddresses[charityId], deadline,
      from, value);
    require(token.transferFrom(from, newQuestion, value));
    registry.add(newQuestion);
  }
}
