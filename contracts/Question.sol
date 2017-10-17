pragma solidity ^0.4.15;

import "./ERC20Token.sol";

contract Question {
  uint public constant version = 1;

  struct Charity {
    string name;
    address addr;
  }

  ERC20Interface token;
  Charity[] public charities;
  string public question;
  string public twitterAccount;
  uint public deadline;
  string public tweetUrl;
  mapping(address => uint256) public donorDonations;
  uint public donorCount;
  uint256 public donations;

  modifier beforeDeadline() {
    require(now < deadline);
    _;
  }

  function getCharitiesCount() constant returns (uint) {
    return charities.length;
  }

  function Question(ERC20Interface _token, string _question, string _twitterAccount, uint _deadline) {
    token = _token;
    require(bytes(_question).length != 0);
    require(bytes(_twitterAccount).length != 0);
    // todo check twitter account more carefully
    require(now < _deadline);

    charities.push(Charity({ name: 'Test charity 1',
      addr: 0xfA491DF8780761853D127A9f7b2772D688A0E3B5 }));
    charities.push(Charity({ name: 'Test charity 2',
      addr: 0x45992982736870Fe45c41049C5F785d4E4cc38Ec }));
    charities.push(Charity({ name: 'Test charity 3',
      addr: 0xfA491DF8780761853D127A9f7b2772D688A0E3B5 }));
    charities.push(Charity({ name: 'Test charity 4',
      addr: 0x45992982736870Fe45c41049C5F785d4E4cc38Ec }));

    question = _question;
    twitterAccount = _twitterAccount;
    deadline = _deadline;
  }

  function increase(uint256 amount) beforeDeadline {
    require(token.transferFrom(msg.sender, this, amount));
    if (0 == donorDonations[msg.sender]) donorCount += 1;
    donations += amount;
    donorDonations[msg.sender] += amount;
  }

  function answer(string _tweetUrl) beforeDeadline {
    require(bytes(_tweetUrl).length != 0);
    // todo check tweet more carefully, get charity id
    tweetUrl = _tweetUrl;
    assert(token.transfer(charities[0].addr, donations));
  }

  function revertDonation()  {
    require(bytes(tweetUrl).length == 0);
    require(now >= deadline);
    require(donorDonations[msg.sender] != 0);
    assert(token.transfer(msg.sender, donorDonations[msg.sender]));
    donorCount -= 1;
    donations -= donorDonations[msg.sender];
    donorDonations[msg.sender] = 0;
  }
}
