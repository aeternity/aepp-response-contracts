/* global artifacts contract it assert web3 */

const Web3_1_0 = require('web3');
const { assertError } = require('./common');

const AEToken = artifacts.require('AEToken');
const Question = artifacts.require('Question');
const QuestionCreator = artifacts.require('QuestionCreator');
const ContractRegistry = artifacts.require('ContractRegistry');

const web3_1_0 = new Web3_1_0(new Web3_1_0.providers.HttpProvider('http://localhost:9000'));
const encodeParameter = web3_1_0.eth.abi.encodeParameter.bind(web3_1_0.eth.abi);
const encodeParameters = web3_1_0.eth.abi.encodeParameters.bind(web3_1_0.eth.abi);
const encodeString = string => encodeParameter('string', string).slice(66);

const week = 7 * 24 * 60 * 60;
let badDeadline;
let goodDeadline;

const increaseTime = (seconds = 0) => new Promise((resolve, reject) =>
  web3.currentProvider.send(
    { jsonrpc: '2.0', method: 'evm_increaseTime', params: [seconds] },
    (err, response) => {
      if (err) reject(err);
      else {
        const increasedSeconds = response.result;
        badDeadline = Math.floor(Date.now() / 1000) + (increasedSeconds + week - 300);
        goodDeadline = Math.floor(Date.now() / 1000) + (increasedSeconds + week + 300);
        resolve(increasedSeconds);
      }
    }));

// https://github.com/ethereumjs/testrpc/issues/390
increaseTime().then(() => {
  const testBackend = '0xfa491df8780761853d127a9f7b2772d688a0e3b5';
  const testAccount = 'test_account';
  const testQuestion = 'test_question';
  const testAmount = 1;
  const testCharityId = 2;
  const testCharity = '0x45992982736870fe45c41049c5f785d4e4cc38ec';
  const testAnswer = 123;

  contract('Question', (accounts) => {
    it('should be deployable', () =>
      Question.new(
        AEToken.address, testBackend, testAccount, testQuestion,
        testCharity, goodDeadline, accounts[0], testAmount)
        .then(instance => instance.version.call().then(c => assert.equal(c, 1))));

    it('deadline must be at least one week after current date', () =>
      Question.new(
        AEToken.address, testBackend, testAccount, testQuestion,
        testCharity, badDeadline, accounts[0], testAmount)
        .then(assert.fail, assertError));

    it('increase', () =>
      Promise.all([
        Question.new(
          AEToken.address, testBackend, testAccount, testQuestion,
          testCharity, goodDeadline, accounts[0], testAmount),
        AEToken.deployed(),
      ]).then(([question, token]) =>
        token.approveAndCall(question.address, testAmount * 2,
          encodeParameter('uint', 32 * 4), { from: accounts[1] })
          .then(() => Promise.all([
            question.donations().then(d => assert.equal(d, testAmount * 3)),
            question.donorAmounts(accounts[0]).then(amount => assert.equal(amount, testAmount)),
            question.donorAmounts(accounts[1]).then(amount => assert.equal(amount, testAmount * 2)),
            question.highestDonors(0).then(([addr]) => assert.equal(addr, accounts[1])),
            question.highestDonors(1).then(([addr]) => assert.equal(addr, accounts[0])),
            question.donorCount().then(d => assert.equal(d, 2)),
          ]))));

    it('can\'t increase after deadline', () =>
      Promise.all([
        Question.new(
          AEToken.address, testBackend, testAccount, testQuestion,
          testCharity, goodDeadline, accounts[0], testAmount),
        AEToken.deployed(),
      ]).then(([question, token]) =>
        increaseTime(week + 1000)
          .then(() => token.approveAndCall(question.address, testAmount * 2,
            encodeParameter('uint', 32 * 4), { from: accounts[1] }))
          .then(assert.fail, assertError)));

    const createQuestion = () => {
      const length =
        encodeString(testAccount).length / 2 +
        encodeString(testQuestion).length / 2 +
        32 * 2;
      const bytes = [
        encodeParameters(['uint', 'uint'], [32 * 4, length]),
        encodeString(testAccount),
        encodeString(testQuestion),
        encodeParameters(['uint', 'uint'], [testCharityId, goodDeadline]).slice(2),
      ].join('');

      return Promise.all([
        AEToken.deployed(),
        QuestionCreator.deployed(),
        ContractRegistry.deployed(),
      ])
        .then(([token, creator, registry]) =>
          token.approveAndCall(creator.address, testAmount, bytes)
            .then(() => registry.getContractsCount())
            .then(count => registry.contracts(count - 1))
            .then(contract => Question.at(contract))
            .then(question => [question, token]));
    };

    it('answer', () =>
      createQuestion()
        .then(([question, token]) =>
          token.balanceOf(testCharity)
            .then(balanceBefore =>
              question.answer(testAnswer, { from: accounts[1] })
                .then(() => Promise.all([
                  question.tweetId().then(t => assert.equal(t, testAnswer)),
                  token.balanceOf(testCharity).then(balanceAfter =>
                    assert.equal(balanceAfter, +balanceBefore + testAmount)),
                ])))));

    it('can\'t answer after deadline', () =>
      createQuestion()
        .then(([question]) =>
          increaseTime(week + 1000)
            .then(() => question.answer(testAnswer, { from: accounts[1] })))
        .then(assert.fail, assertError));

    it('answerable only by backend', () =>
      createQuestion()
        .then(([question]) => question.answer(testAnswer))
        .then(assert.fail, assertError));

    it('revert donation', () =>
      createQuestion()
        .then(([question, token]) =>
          increaseTime(week + 1000)
            .then(() => token.balanceOf(accounts[0]))
            .then(balanceBefore =>
              question.revertDonation()
                .then(() => Promise.all([
                  token.balanceOf(accounts[0])
                    .then(balanceAfter => assert.equal(balanceAfter, +balanceBefore + testAmount)),
                  question.donorRevertDonation(accounts[0])
                    .then(revertDonation => assert.isTrue(revertDonation)),
                ])))));

    it('can\'t revert donation before deadline', () =>
      createQuestion()
        .then(([question, token]) => question.revertDonation())
        .then(assert.fail, assertError));
  });
});
