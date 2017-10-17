pragma solidity ^0.4.15;

contract ContractRegistry {
  address[] public contracts;
  address owner;
  address recorder;

  modifier onlyOwner {
    require(msg.sender == owner);
    _;
  }

  modifier onlyRecorder {
    require(msg.sender == recorder);
    _;
  }

  event Added(address contractAddress);

  function getContractsCount() constant returns (uint) {
    return contracts.length;
  }

  function ContractRegistry() {
    owner = msg.sender;
  }

  function setRecorder(address _recorder) onlyOwner {
    recorder = _recorder;
  }

  function add(address _contract) onlyRecorder {
    contracts.push(_contract);
    Added(_contract);
  }
}
