const AEToken = artifacts.require('AEToken');
const ContractRegistry = artifacts.require('ContractRegistry');
const QuestionCreator = artifacts.require('QuestionCreator');

module.exports = (deployer, environment, accounts) => {
  deployer.deploy(ContractRegistry)
    .then(() => deployer.deploy(AEToken, 1000, 'test', 1, 'test'))
    .then(() => deployer.deploy(
      QuestionCreator, ContractRegistry.address, AEToken.address, accounts[1]))
    .then(() => Promise.all([
      AEToken.deployed()
        .then(token => token.prefill(accounts, (new Array(10)).fill(10))
          .then(() => token.launch())),
      ContractRegistry.deployed()
        .then(registry => registry.setRecorder(QuestionCreator.address)),
    ]));
};
