/* global artifacts contract it assert web3 */

const { assertError } = require('./common');

const ERC20Token = artifacts.require('ERC20Token');
const Question = artifacts.require('Question');

const increaseTime = (seconds = 0) => web3.currentProvider.send({
  jsonrpc: '2.0', method: 'evm_increaseTime', params: [seconds] }).result;

// https://github.com/ethereumjs/testrpc/issues/390
const increasedSeconds = increaseTime();
const testBeforeNowDate = Math.floor(Date.now() / 1000) + (increasedSeconds - 5);
const testAfterNowDate = Math.floor(Date.now() / 1000) + (increasedSeconds + 5);
const testQuestion = 'test_question';
const testAccount = 'test_account';
const testAnswer = 'test_answer';

contract('Question', (accounts) => {
  it('can\'t be deployed with unset question', () =>
    Question.new(ERC20Token.address, '', testAccount, testAfterNowDate)
      .then(assert.fail, assertError));

  it('can\'t be deployed with unset account', () =>
    Question.new(ERC20Token.address, testQuestion, '', testAfterNowDate)
      .then(assert.fail, assertError));

  it('can\'t be deployed with deadline before current date', () =>
    Question.new(ERC20Token.address, testQuestion, testAccount, testBeforeNowDate)
      .then(assert.fail, assertError));

  it('should be deployable', () =>
    Question.new(ERC20Token.address, testQuestion, testAccount, testAfterNowDate)
      .then(instance =>
        Promise.all([
          instance.version.call().then(c => assert.equal(c, 1)),
          instance.getCharitiesCount.call().then(c => assert.equal(c, 4)),
          instance.question.call().then(q => assert.equal(q, testQuestion)),
          instance.twitterAccount.call().then(t => assert.equal(t, testAccount)),
          instance.deadline.call().then(d => assert.equal(d, testAfterNowDate)),
        ])));

  it('can\'t increase after deadline', () =>
    Question.new(ERC20Token.address, testQuestion, testAccount, testBeforeNowDate)
      .then(question => question.increase(0))
      .then(assert.fail, assertError));

  const newDonatedQuestion = amount =>
    Promise.all([
      Question.new(ERC20Token.address, testQuestion, testAccount, testAfterNowDate),
      ERC20Token.deployed(),
    ])
      .then(([question, token]) =>
        token.approve(question.address, amount)
          .then(() => question.increase(amount))
          .then(() => question));

  it('increase', () => {
    const amount = 1;
    return newDonatedQuestion(amount)
      .then(question =>
        Promise.all([
          question.donorDonations.call(accounts[0]).then(d => assert.equal(d, amount)),
          question.donorCount.call().then(c => assert.equal(c, 1)),
          question.donations.call().then(d => assert.equal(d, amount)),
        ]));
  });

  it('can\'t answer after deadline', () =>
    Question.new(ERC20Token.address, testQuestion, testAccount, testBeforeNowDate)
      .then(question => question.answer(testAnswer))
      .then(assert.fail, assertError));

  it('answer', () =>
    newDonatedQuestion(1)
      .then(question =>
        question.answer(testAnswer)
          .then(() => question.tweetUrl.call()))
      .then(t => assert.equal(t, testAnswer)));

  it('answer with transfer to charity', () => {
    const amount = 1;
    return Promise.all([
      newDonatedQuestion(amount),
      ERC20Token.deployed(),
    ])
      .then(([question, token]) =>
        question.charities.call(0)
          .then(([, charityAddress]) =>
            token.balanceOf.call(charityAddress)
              .then(charityBalance =>
                question.answer(testAnswer)
                  .then(() => token.balanceOf.call(charityAddress))
                  .then(newCharityBalance =>
                    assert.equal(newCharityBalance.comparedTo(charityBalance.plus(amount)), 0)))));
  });

  it('can\'t revert donation before deadline', () => {
    const amount = 1;
    return newDonatedQuestion(amount)
      .then(question => question.revertDonation())
      .then(assert.fail, assertError);
  });

  it('revert donation', () => {
    const amount = 1;
    return Promise.all([
      newDonatedQuestion(amount)
        .then((token) => {
          increaseTime(10);
          return token;
        }),
      ERC20Token.deployed(),
    ])
      .then(([question, token]) =>
        token.balanceOf.call(accounts[0])
          .then(accountBalance =>
            question.revertDonation()
              .then(() => token.balanceOf.call(accounts[0]))
              .then(newAccountBalance =>
                assert.equal(newAccountBalance.comparedTo(accountBalance.plus(amount)), 0))));
  });
});
