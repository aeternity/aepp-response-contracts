
import "./HumanStandardToken.sol";

pragma solidity ^0.4.15;

contract PrefilledToken is HumanStandardToken {

  bool public prefilled = false;
  address public creator = msg.sender;

  function prefill (address[] _addresses, uint[] _values)
    only_not_prefilled
    only_creator
  {
    uint total = totalSupply;

    for (uint i = 0; i < _addresses.length; i++) {
      address who = _addresses[i];
      uint val = _values[i];

      if (balances[who] != val) {
        total -= balances[who];

        balances[who] = val;
        total += val;
				Transfer(0x0, who, val);
      }
    }

    totalSupply = total;
  }

  function launch ()
    only_not_prefilled
    only_creator
  {
    prefilled = true;
  }

  /**
   * Following standard token methods needs to wait
   * for the Token to be prefilled first.
   */

  function transfer(address _to, uint256 _value) returns (bool success) {
		assert(prefilled);

    return super.transfer(_to, _value);
  }

  function transferFrom(address _from, address _to, uint256 _value) returns (bool success) {
		assert(prefilled);

    return super.transferFrom(_from, _to, _value);
  }

  function approve(address _spender, uint256 _value) returns (bool success) {
		assert(prefilled);

    return super.approve(_spender, _value);
  }

  modifier only_creator () {
		require(msg.sender == creator);
    _;
  }

  modifier only_not_prefilled () {
		assert(!prefilled);
    _;
  }
}
