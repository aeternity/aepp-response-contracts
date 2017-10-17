/* global artifacts contract it assert */

const ContractRegistry = artifacts.require('ContractRegistry');
const Question = artifacts.require('Question');
const QuestionCreator = artifacts.require('QuestionCreator');

const testQuestion = 'test_question';
const testAccount = 'test_account';
const testDate = (new Date('2100-01-01')).getTime() / 1000;

contract('QuestionCreator', () => {
  it('create question', () =>
    Promise.all([
      QuestionCreator.deployed(),
      ContractRegistry.deployed(),
    ])
      .then(([creator, registry]) =>
        creator.create(testQuestion, testAccount, testDate)
          .then(() => registry.contracts.call(0))
          .then(contract => Question.at(contract))
          .then(question =>
            Promise.all([
              question.question.call().then(q => assert.equal(q, testQuestion)),
              question.twitterAccount.call().then(t => assert.equal(t, testAccount)),
              question.deadline.call().then(d => assert.equal(d, testDate)),
            ]))));
});
