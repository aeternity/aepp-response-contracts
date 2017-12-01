import "./PrefilledToken.sol";

pragma solidity ^0.4.15;

contract AEToken is PrefilledToken {

  // Date when the tokens won't be transferable anymore
  uint public transferableUntil;

  /**
   * HumanStandardToken(
      uint256  initialAmount,
      string   tokenName,
      uint8    decimalUnits,
      string   tokenSymbol
    )
   */
  function AEToken() HumanStandardToken(0, "Aeternity", 18, "AE") {
    uint nYears = 2;

    transferableUntil = now + (60 * 60 * 24 * 365 * nYears);
  }

  function transfer(address _to, uint256 _value) only_transferable returns (bool success) {
    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) only_transferable returns (bool success) {
    return super.transferFrom(_from, _to, _value);
  }

  modifier only_transferable () {
		assert(now <= transferableUntil);
    _;
  }
}
