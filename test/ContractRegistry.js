/* global artifacts contract it assert */

const { assertError } = require('./common');

const ContractRegistry = artifacts.require('ContractRegistry');

const testContractAddress = '0x7e8a8a78e0938cde6fd89ce47c1319b82d5e4022';

contract('ContractRegistry', (accounts) => {
  it('can\'t set recorder by not the owner', () =>
    ContractRegistry.deployed()
      .then(instance => instance.setRecorder(accounts[1], { from: accounts[1] }))
      .then(assert.fail, assertError));

  it('set recorder', () =>
    ContractRegistry.deployed()
      .then(instance => instance.setRecorder(accounts[1])));

  it('can\'t add contract by not the recorder', () =>
    ContractRegistry.deployed()
      .then(instance => instance.add(testContractAddress))
      .then(assert.fail, assertError));

  it('add contract', () =>
    ContractRegistry.deployed()
      .then(registry =>
        registry.setRecorder(accounts[1])
          .then(() => registry.add(testContractAddress, { from: accounts[1] }))
          .then(() => registry.getContractsCount.call())
          .then(contractsCount => assert.equal(contractsCount, 1))
          .then(() => registry.contracts.call(0))
          .then(contract => assert.equal(contract, testContractAddress))));

  it('add contract invokes Added event', () =>
    ContractRegistry.deployed()
      .then((registry) => {
        const filter = registry.Added();
        return registry.setRecorder(accounts[0])
          .then(() => registry.add(testContractAddress))
          .then(() => {
            const events = filter.get();
            assert.equal(events.length, 1);
            assert.equal(events[0].args.contractAddress, testContractAddress);
          });
      }));
});
