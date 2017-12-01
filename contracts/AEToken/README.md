# Solidity contracts

## token.sol

This is the abstract contract that represents the ERC 20 standard as proposed
[here](https://github.com/ethereum/EIPs/issues/20).

## standard-token.sol

Standard token is the actual implementation of the standard but by itself not
really all that useful.

## human-standard-token.sol

The human standard token adds some optional properties to the standard token, such
as a human readable name, see [here for some more details](https://media.consensys.net/how-to-create-your-own-tokens-standard-token-factory-for-humans-deployed-e92649a1bb5e).

## prefilled-token.sol

The distribution for the AE token (ERC20 token on Ethereum)
happens via a contract that gets filled with all the contributions.
The `prefill(address[] _addresses, uint[] _values)` function does just that. After
the contract has been created, the `prefill` function will be called to distribute
the tokens. Calling the `prefill` function is only possible as long as the `prefilled`
variable is set to `false`, i.e. the prefilling has not finished yet. Calling the
`transfer`, `transferFrom`, and `approve` functions is also not possible while the
`prefilled` is set to `false`. Setting the `prefilled` variable to `true` is only
possible via calling the `launch()` function and there's no way to revert this
change, thus making it impossible to create more tokens after launching.

## ae-token.sol

This the actual token that gets created and differs from the prefilled token only
by adding a time limit up until tokens can be transfered. Tokens will become
non-transferable as they are intended to be exchanged for the native coins
of the Aeternity blockchain once it is ready.
