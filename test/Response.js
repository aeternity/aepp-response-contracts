const _ = require('lodash');
const Web3_1_0 = require('web3');

const web3_1_0 = new Web3_1_0();
const AEToken = artifacts.require('AEToken');
const Response = artifacts.require('Response');

const assertError = error =>
    assert.equal(error.message, 'VM Exception while processing transaction: invalid opcode');

const encodeParameters = web3_1_0.eth.abi.encodeParameters.bind(web3_1_0.eth.abi);

const month = 30 * 24 * 60 * 60;
const testAccount = 123;
const testQuestion = '0xc0ffee0000000000000000000000000000000000000000000000000000000000';
const testAmount = 2;
const testAnswer = 321;

let testDeadline;
const updateTestDeadline = seconds => {
  const d = seconds ? new Date(seconds * 1000) : new Date();
  d.setMonth(d.getMonth() + 6);
  testDeadline = Math.floor(d / 1000);
};
updateTestDeadline();

const increaseTime = (seconds = 0) => new Promise((resolve, reject) =>
  web3.currentProvider.send(
    { jsonrpc: '2.0', method: 'evm_increaseTime', params: [seconds] },
    (err, response) => {
      if (err) reject(err);
      else {
        const increasedSeconds = response.result;
        const seconds = Math.floor(Date.now() / 1000) + increasedSeconds;
        updateTestDeadline(seconds);
        resolve(seconds);
      }
    }));

const getBalance = account => new Promise((resolve, reject) =>
  web3.eth.getBalance(account, (err, response) => {
    if (err) reject(err);
    else resolve(response);
  }));

contract('Response', (accounts) => {
  const testToken = accounts[0];
  const testBackend = accounts[1];
  const testFoundation = accounts[2];

  const createQuestion = ({
    content = testQuestion,
    twitterUserId = testAccount,
    foundation = testFoundation,
    amount = testAmount,
  } = {}) => {
    return Promise.all([
      AEToken.deployed(),
      Response.deployed(),
    ])
      .then(([token, response]) =>
        token.approve(response.address, amount)
          .then(() =>
            response.createQuestion(twitterUserId, content, foundation, amount))
          .then(() => response.questionCount())
          .then(count => [response, count - 1, token]));
  };

  it('set backend', () =>
    Response.new(testToken).then(response => response.setBackend(accounts[2])));

  it('can\'t set backend by not the owner', () =>
    Response.new(testToken).then(response =>
      response.setBackend(accounts[2], { from: accounts[1] })
        .then(assert.fail, assertError)));

  it('set backend fee', () =>
    Response.new(testToken).then(response =>
      response.setBackend(accounts[1])
        .then(() => response.setBackendFee(testAmount, { from: accounts[1] }))
        .then(() => response.backendFee())
        .then(backendFee => assert.equal(backendFee, testAmount))));

  it('can\'t set backend fee by not the backend', () =>
    Response.new(testToken).then(response =>
      response.setBackendFee(testAmount, { from: accounts[1] })
        .then(assert.fail, assertError)));

  it('set foundation', () =>
    Response.new(testToken).then(response =>
      response.setFoundation(accounts[1], true)));

  it('can\'t set foundation by not the owner', () =>
    Response.new(testToken).then(response =>
      response.setFoundation(accounts[2], true, { from: accounts[1] })
        .then(assert.fail, assertError)));

  const genSupportBytes = (questionIdx) =>
    encodeParameters(['uint', 'uint', 'uint'], [32 * 4, 32, questionIdx]);

  it('create question', () =>
    Promise.all([
      AEToken.deployed(),
      Response.deployed(),
    ])
      .then(([token, response]) => Promise.all([
        token.balanceOf(response.address).then(balance => +balance),
        response.questionCount().then(count => +count),
        testQuestion,
      ])
        .then(([amountBefore, countBefore, question]) =>
          createQuestion({ content: question })
            .then(() => response.questionCount())
            .then(count => {
              assert.equal(count, countBefore + 1);
              return count - 1;
            })
            .then(questionIdx =>
              Promise.all([
                response.questions(questionIdx).then(([
                  twitterUserId, content, author, foundation,
                  createdAt, questionTweetId, answerTweetId, supporterCount, amount
                ]) => {
                  assert.equal(twitterUserId, testAccount);
                  assert.equal(content, question);
                  assert.equal(author, accounts[0]);
                  assert.equal(foundation, testFoundation);
                  assert.equal(questionTweetId, 0);
                  assert.equal(answerTweetId, 0);
                  assert.equal(supporterCount, 1);
                  assert.equal(amount, testAmount);
                }),
                response.supporterAmount(questionIdx, accounts[0])
                  .then(amount => assert.equal(amount, testAmount)),
                response.supportRevertedAt(questionIdx, accounts[0])
                  .then(supportRevertedAt => assert.equal(supportRevertedAt, 0)),
                response.highestSupporter(questionIdx, 0).then(([address, supportAt, amount]) => {
                  assert.equal(address, accounts[0]);
                  assert.equal(amount, testAmount);
                }),
                token.balanceOf(response.address)
                  .then(d => assert.equal(d, amountBefore + testAmount)),
              ])))));

  it('create question with backend fee', () =>
    AEToken.deployed().then(token =>
      Response.new(token.address).then(response =>
        Promise.all([
          response.setBackend(accounts[1]),
          response.setFoundation(accounts[2], true),
          token.approve(response.address, testAmount),
        ])
          .then(() => response.setBackendFee(testAmount, { from: accounts[1] }))
          .then(() => getBalance(accounts[1]))
          .then(backendBalanceBefore =>
            response.createQuestion(
              testAccount, testQuestion, accounts[2],
              testAmount, { value: testAmount })
              .then(() => getBalance(accounts[1]))
              .then(backendBalance =>
                assert.equal(+backendBalance, +backendBalanceBefore + testAmount))))));

  it('can\'t create question without backend fee', () =>
    AEToken.deployed().then(token =>
      Response.new(token.address).then(response =>
        Promise.all([
          response.setBackend(accounts[1]),
          response.setFoundation(accounts[2], true),
          token.approve(response.address, testAmount),
        ])
          .then(() => response.setBackendFee(testAmount, { from: accounts[1] }))
          .then(() =>
            response.createQuestion(
              testAccount, testQuestion, accounts[2], testAmount)
              .then(assert.fail, assertError)))));

  it('increase by the same account', () =>
    createQuestion().then(([response, questionIdx, token]) =>
      token.approveAndCall(response.address, testAmount * 2, genSupportBytes(questionIdx))
        .then(() => Promise.all([
          response.questions(questionIdx).then(([
            twitterUserId, content, author, foundation,
            createdAt, questionTweetId, answerTweetId, supporterCount, amount
          ]) => {
            assert.equal(supporterCount, 1);
            assert.equal(amount, testAmount * 3);
          }),
          response.supporterAmount(questionIdx, accounts[0])
            .then(amount => assert.equal(amount, testAmount * 3)),
          response.highestSupporter(questionIdx, 0).then(([address, supportAt, amount]) => {
            assert.equal(address, accounts[0]);
            assert.equal(amount, testAmount * 3);
          }),
        ]))));

  it('increase', () =>
    createQuestion().then(([response, questionIdx, token]) =>
      token.approveAndCall(response.address, testAmount * 2,
        genSupportBytes(questionIdx), { from: accounts[1] })
        .then(() => Promise.all([
          response.questions(questionIdx).then(([
            twitterUserId, content, author, foundation,
            createdAt, questionTweetId, answerTweetId, supporterCount, amount
          ]) => {
            assert.equal(supporterCount, 2);
            assert.equal(amount, testAmount * 3);
          }),
          response.supporterAmount(questionIdx, accounts[0])
            .then(amount => assert.equal(amount, testAmount)),
          response.supporterAmount(questionIdx, accounts[1])
            .then(amount => assert.equal(amount, testAmount * 2)),
          response.highestSupporter(questionIdx, 0).then(([address, supportAt, amount]) => {
            assert.equal(address, accounts[1]);
            assert.equal(amount, testAmount * 2);
          }),
          response.highestSupporter(questionIdx, 1).then(([address, supportAt, amount]) => {
            assert.equal(address, accounts[0]);
            assert.equal(amount, testAmount);
          }),
        ]))));

  it('increase by multiple accounts ', () =>
    Promise.all([
      createQuestion(),
      (() => {
        const supporterCount = 6;
        const supports = [
          ..._.times(supporterCount, accountIdx => ({ amount: _.random(1, 5), accountIdx })),
          ..._.times(supporterCount, () =>
            ({ amount: _.random(1, 5), accountIdx: _.random(supporterCount - 1) })),
        ];
        const amounts = supports.reduce((p, { amount, accountIdx }) => {
          p[accountIdx] += amount;
          return p;
        }, _.times(6, () => 0));
        amounts[0] += testAmount;
        const f = v => supports.map(({ accountIdx }) => accountIdx).lastIndexOf(v);
        const addresses = amounts
          .map((amount, accountIdx) => ({ amount, accountIdx }))
          .sort((a, b) => b.amount - a.amount || f(a.accountIdx) - f(b.accountIdx))
          .map(({ accountIdx }) => accounts[accountIdx])
          .slice(0, 5);
        return [supporterCount, supports, amounts, addresses];
      })(),
    ])
      .then(([[response, questionIdx, token], [supporterCount, supports, amounts, addresses]]) =>
        Promise.all(
          supports.map(({ amount, accountIdx }) => token
            .approveAndCall(response.address, amount,
              genSupportBytes(questionIdx), { from: accounts[accountIdx] })))
          .then(() => Promise.all([
            response.questions(questionIdx).then(([
              twitterUserId, content, author, foundation,
              createdAt, questionTweetId, answerTweetId, _supporterCount, amount
            ]) => {
              assert.equal(_supporterCount, supporterCount);
              assert.equal(amount, _.sum(amounts));
            }),
            Promise.all(_.times(supporterCount, idx =>
              response.supporterAmount(questionIdx, accounts[idx])))
              .then(a => assert.deepEqual(a.map(i => +i), amounts)),
            Promise.all(_.times(5, idx =>
              response.highestSupporter(questionIdx, idx).then(([address]) => address)))
              .then(a => assert.deepEqual(a, addresses)),
          ]))));

  it('can\'t increase after deadline', () =>
    createQuestion()
      .then(([response, questionIdx, token]) =>
        increaseTime(month + 1000)
          .then(() =>
            token.approveAndCall(response.address, testAmount, genSupportBytes(questionIdx))
              .then(assert.fail, assertError))));

  it('setAnswerTweetId', () =>
    createQuestion().then(([response, questionIdx, token]) =>
      token.balanceOf(testFoundation)
        .then(balanceBefore =>
          response.setAnswerTweetId(questionIdx, testAnswer, { from: testBackend })
            .then(() => Promise.all([
              response.questions(questionIdx).then(([
                twitterUserId, content, author, foundation,
                createdAt, questionTweetId, answerTweetId,
              ]) => assert.equal(answerTweetId, testAnswer)),
              token.balanceOf(testFoundation).then(balanceAfter =>
                assert.equal(balanceAfter, +balanceBefore + testAmount)),
            ])))));

  it('can\'t setAnswerTweetId after deadline', () =>
    createQuestion()
      .then(([response, questionIdx]) =>
        increaseTime(month + 1000)
          .then(() => response.setAnswerTweetId(questionIdx, testAnswer, { from: testBackend })
            .then(assert.fail, assertError))));

  it('setAnswerTweetIdable only by backend', () =>
    createQuestion().then(([response, questionIdx]) =>
      response.setAnswerTweetId(questionIdx, testAnswer)
        .then(assert.fail, assertError)));

  it('setQuestionTweetId', () =>
    createQuestion().then(([response, questionIdx]) =>
      response.setQuestionTweetId(questionIdx, testAnswer, { from: testBackend })
        .then(() =>
          response.questions(questionIdx).then(([
            twitterUserId, content, author, foundation,
            createdAt, questionTweetId,
          ]) => assert.equal(questionTweetId, testAnswer)))));

  it('can\'t setQuestionTweetId after deadline', () =>
    createQuestion()
      .then(([response, questionIdx]) =>
        increaseTime(month + 1000)
          .then(() => response.setQuestionTweetId(questionIdx, testAnswer, { from: testBackend })
            .then(assert.fail, assertError))));

  it('setQuestionTweetId only by backend', () =>
    createQuestion().then(([response, questionIdx]) =>
      response.setQuestionTweetId(questionIdx, testAnswer)
        .then(assert.fail, assertError)));

  it('revert support', () =>
    createQuestion()
      .then(([response, questionIdx, token]) =>
        Promise.all([
          token.balanceOf(accounts[0]),
          increaseTime(month + 1000),
        ])
          .then(([balanceBefore]) => response.revertSupport(questionIdx)
            .then(() => Promise.all([
              token.balanceOf(accounts[0])
                .then(balanceAfter => assert.equal(balanceAfter, +balanceBefore + testAmount)),
              response.supportRevertedAt(questionIdx, accounts[0])
                .then(supportRevertedAt => assert.notEqual(supportRevertedAt, 0)),
            ])))));

  it('can\'t revert donation before deadline', () =>
    createQuestion().then(([response, questionIdx]) =>
      response.revertSupport(questionIdx)
        .then(assert.fail, assertError)));
});
