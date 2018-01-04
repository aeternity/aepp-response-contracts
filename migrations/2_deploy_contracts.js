const AEToken = artifacts.require('AEToken');
const Response = artifacts.require('Response');

module.exports = (deployer, environment, accounts) => {
  deployer.deploy(AEToken, 1000000, 'test', 1, 'test', { overwrite: false })
    .then(() => AEToken.deployed())
    .then(token =>
      deployer.deploy(Response, token.address)
        .then(() => Response.deployed())
        .then(response => Promise.all([
          ...environment === 'development' ? [
            response.setBackend(accounts[1]),
            response.setFoundation(accounts[2], 1),
            response.setFoundation(accounts[3], 1),
            token.prefilled()
              .then(prefilled =>
                !prefilled && token.prefill(accounts, (new Array(10)).fill(10000))
                  .then(() => token.launch())),
          ] : [],
          ...environment === 'kovan' ? [
            response.setBackend(accounts[0]),
            response.setFoundation(accounts[0], 1),
          ] : [],
        ])));
};
