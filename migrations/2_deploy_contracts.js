const Store = artifacts.require('Store');
const AEToken = artifacts.require('AEToken');
const ResponseStore = artifacts.require('ResponseStore');
const Response = artifacts.require('Response');

module.exports = (deployer, environment, accounts) => {
  deployer.deploy([
    [Store, { overwrite: false }],
    [AEToken, 1000000, 'test', 1, 'test', { overwrite: false }],
    [ResponseStore, { overwrite: false }],
  ])
    .then(() => Promise.all([
      Store.deployed(),
      AEToken.deployed(),
      deployer.link(ResponseStore, Response),
    ]))
    .then(([store, token]) =>
      deployer.deploy(Response, store.address, token.address)
        .then(() => Response.deployed())
        .then(response =>
          store.setWriteAccess(response.address, true)
            .then(() => Promise.all([
              ...environment === 'development' ? [
                response.setBackend(accounts[1]),
                response.setFoundation(accounts[2], 1),
                response.setFoundation(accounts[3], 1),
                token.prefilled().then(prefilled =>
                  !prefilled && token.prefill(accounts, (new Array(10)).fill(10000))
                    .then(() => token.launch())),
              ] : [],
              ...environment === 'kovan' ? [
                response.setBackend(accounts[0]),
                response.setFoundation(accounts[0], 1),
              ] : [],
            ]))));
};
