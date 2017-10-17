/* global assert */

module.exports = {
  assertError: error =>
    assert.equal(error.message, 'VM Exception while processing transaction: invalid opcode'),
};
