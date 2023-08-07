Using the Create2Factory
=======================

The `ImmutableCreate2Factory` allows for safe Create2 deployment of contracts. It is immutable, meaning that it can only be used to deploy a single contract. This is to ensure that the factory cannot be used to redeploy contracts on one which is already deployed.

When using the `safeCreate2` the create2 salt is required to contain the callees address in the salt. This is to ensure that the contract cannot be deployed by a different address than the one specified in the salt.

