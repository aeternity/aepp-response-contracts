const _ = require('lodash');
const ResponseTest = artifacts.require('ResponseTest');

contract('ResponseTest', (accounts) => {
  let support2GasUse;

  it('support2', () =>
    ResponseTest.new()
      .then(response =>
        Promise.all(accounts.slice(0, 10).map(account => response.support2(1, { from: account }))))
      .then(transactions => transactions.map(({ receipt: { gasUsed } }) => gasUsed))
      .then((gasUses) => {
        support2GasUse = gasUses[0];
        gasUses.forEach(gasUsed => assert.equal(support2GasUse, gasUsed));
        console.log('support2 gas usage is', support2GasUse);
      }));

  const genTest = (methodName, name, quires) =>
    it([methodName, name].join(', '), () =>
      ResponseTest.new()
        .then(response => new Promise((resolve) => {
          const transactions = [];
          const f = ({ account, amount }) =>
            response[methodName](amount, { from: account })
              .then(r => transactions.push(r));
          quires
            .reduce(
              (promise, args) => promise.then(() => f(args)),
              Promise.resolve())
            .then(() => resolve(transactions));
        }))
        .then(transactions => transactions.map(({ receipt: { gasUsed } }) => gasUsed))
        .then(gasUses => {
          console.log([methodName, name].join(', '));
          const t1 = _.sum(gasUses);
          const t2 = support2GasUse * gasUses.length;
          console.log(
            `s1 gas ${t1}, s2 gas ${t2}, ${Math.round((1 - t1 / t2) * 100)}%` +
            `, ${gasUses.length} transactions, min gas ${Math.min(...gasUses)}` +
            `, max gas ${Math.max(...gasUses)}`);
          console.log(gasUses.slice(0, 8).join(', '));
        }));

  genTest('support1', 'the same amount',
    accounts.map((account) => ({ account, amount: 1 })));

  genTest('support1', 'increasing amount',
    accounts.map((account, idx) => ({ account, amount: idx + 1 })));

  genTest('support1', 'random amount',
    accounts.map((account) => ({ account, amount: Math.round(Math.random() * 1000) })));
});
