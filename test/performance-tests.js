const _ = require('lodash');
const Simplest = artifacts.require('Simplest');
const BubbleSort = artifacts.require('BubbleSort');
const RewriteMin = artifacts.require('RewriteMin');
const RewriteMinPreCalculated = artifacts.require('RewriteMinPreCalculated');

contract('Simplest', (accounts) => {
  let simplestGasUsage;

  it('Simplest', () =>
    Simplest.new()
      .then(response =>
        Promise.all(accounts.slice(0, 10).map(account => response.support(1, { from: account }))))
      .then(transactions => transactions.map(({ receipt: { gasUsed } }) => gasUsed))
      .then((gasUses) => {
        simplestGasUsage = gasUses[0];
        gasUses.forEach(gasUsed => assert.equal(simplestGasUsage, gasUsed));
        console.log('Simplest gas usage is', simplestGasUsage);
        simplestGasUsage *= accounts.length;
        console.log('Overall gas usage is', simplestGasUsage);
        console.log('Transaction amount per test is', accounts.length);
      }));

  const genTest = (contract, name, quires) =>
    it([contract.contractName, name].join(', '), () =>
      contract.new()
        .then(response => new Promise((resolve) => {
          const transactions = [];
          const f = ({ account, amount }) =>
            response.support(amount, { from: account })
              .then(r => transactions.push(r));
          quires
            .reduce(
              (promise, args) => promise.then(() => f(args)),
              Promise.resolve())
            .then(() => resolve(transactions));
        }))
        .then(transactions => transactions.map(({ receipt: { gasUsed } }) => gasUsed))
        .then(gasUses => {
          console.log(`\n${contract.contractName}, ${name}`);
          const gasUsage = _.sum(gasUses);
          console.log(
            `gas ${gasUsage}, ${Math.round((1 - gasUsage / simplestGasUsage) * 100)}%` +
            `, min gas ${Math.min(...gasUses)}, max gas ${Math.max(...gasUses)}`);
          console.log(gasUses.slice(0, 8).join(', '));
        }));

  [BubbleSort, RewriteMin, RewriteMinPreCalculated].forEach((contract) => {
    genTest(contract, 'the same amount',
      accounts.map((account) => ({ account, amount: 1 })));

    genTest(contract, 'increasing amount',
      accounts.map((account, idx) => ({ account, amount: idx + 1 })));

    genTest(contract, 'random amount',
      accounts.map((account) => ({ account, amount: Math.round(Math.random() * 1000) })));
  })
});
