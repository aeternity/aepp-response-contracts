/* global artifacts contract it assert */

const Web3_1_0 = require('web3');

const web3_1_0 = new Web3_1_0();
const AEToken = artifacts.require('AEToken');
const ContractRegistry = artifacts.require('ContractRegistry');
const Question = artifacts.require('Question');
const QuestionCreator = artifacts.require('QuestionCreator');

contract('QuestionCreator', (accounts) => {
  const testAmount = 3;
  const testCharityId = 2;
  const testCharityAddress = '0x45992982736870fe45c41049c5f785d4e4cc38ec';
  const testDate = (new Date('2100-01-01')).getTime() / 1000;
  const encodeParameter = web3_1_0.eth.abi.encodeParameter.bind(web3_1_0.eth.abi);
  const encodeParameters = web3_1_0.eth.abi.encodeParameters.bind(web3_1_0.eth.abi);
  const encodeString = string => encodeParameter('string', string).slice(66);

  const genCreateQuestionTest = repeat => () => {
    const testAccount = 'test_account'.repeat(repeat);
    const testQuestion = 'test_question'.repeat(repeat);
    const length =
      encodeString(testAccount).length / 2 +
      encodeString(testQuestion).length / 2 +
      32 * 2;
    const bytes = [
      encodeParameters(['uint', 'uint'], [32 * 4, length]),
      encodeString(testAccount),
      encodeString(testQuestion),
      encodeParameters(['uint', 'uint'], [testCharityId, testDate]).slice(2),
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
          .then(question =>
            Promise.all([
              question.version().then(c => assert.equal(c, 1)),
              question.twitterAccount().then(t => assert.equal(t, testAccount)),
              question.question().then(q => assert.equal(q, testQuestion)),
              question.charityAddress().then(q => assert.equal(q, testCharityAddress)),
              question.deadline().then(d => assert.equal(d, testDate)),
              question.donorAmounts(accounts[0]).then(amount => assert.equal(amount, testAmount)),
              question.highestDonors(0).then(([addr]) => assert.equal(addr, accounts[0])),
              question.donorCount().then(d => assert.equal(d, 1)),
              question.donations().then(d => assert.equal(d, testAmount)),
              token.balanceOf(question.address).then(d => assert.equal(d, testAmount)),
            ])));
  };

  it('create question', genCreateQuestionTest(1));
  it('create question with strings longer than 32 bytes', genCreateQuestionTest(16));
});
