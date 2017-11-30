const ERC20Token = artifacts.require('ERC20Token');
const ContractRegistry = artifacts.require('ContractRegistry');
const QuestionCreator = artifacts.require('QuestionCreator');

module.exports = (deployer) => {
  deployer
    .deploy([ERC20Token, ContractRegistry])
    .then(() => deployer.deploy(QuestionCreator, ContractRegistry.address, ERC20Token.address))
    .then(() => ContractRegistry.deployed())
    .then(registry => registry.setRecorder(QuestionCreator.address));
};
