Rethereum Create2 Ecosystem
=================
Write about create and explain what create 2 acheives

### Create2
Create2 is a new opcode that was introduced in the Constantinople fork. This opcode allows a contract to be deployed to a deterministic address, without having to deploy it first to a temporary address and then using the `SELFDESTRUCT` opcode to transfer the contract to the desired address.

The opcode takes 4 inputs:
- The constructor calldata
- The size of the contract
- The contract bytecode
- A salt

The opcode then calculates the contract address using the following formula:
```
address = keccak256(0xff ++ address ++ salt ++ keccak256(abi.encodePacked(init_code))[12:]
```
Where the `++` operator denotes concatenation, `address` is the address of the contract that will be deploying the new contract, `salt` is the salt, and `init_code` is the contract bytecode.

### Create2 Use Cases
Create2 is useful in the following scenarios:
- Deploying a contract to an address that is known in advance. For example, a contract that is deployed to a namehash of a domain name.
- Deploying a contract to an address that is derived from the address of another contract. For example, a factory contract that deploys new contracts.
- Deploying a contract to an address that is derived from a hash of the contract bytecode. For example, a contract that allows users to create a contract that stores information about them. 
