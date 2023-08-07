// SPDX-License-Identifier: GPL-2
pragma solidity ^0.8.0;

interface ImmutableCreate2Factory {
    function findCreate2AddressViaHash(bytes32 salt, bytes32 initCodeHash) external view returns (address deploymentAddress);
}

contract Create2Mining {
    uint256 public constant MINIMUM_BID = 10 ether;
    address public constant CREATE2_FACTORY = 0x00000000000e974Fb8B2985Eb2fda6Dd13b90ACb;

    event NewBid(address indexed bidder, uint256 amount, bytes32 hash, uint8 zeros);
    event NewSolution(address indexed bidder, address indexed miner, bytes32 hash, bytes32 solution, address addr);
    event BidWithdrawn(address indexed bidder, uint256 amount, bytes32 hash, uint8 zeros);

    struct Bid {
        address bidder;
        uint256 amount;
        bytes32 hash;
        uint8 zeros;
        bytes32 solution;
    }

    Bid[] public bids;

    // @dev Submit a bid for a solution to mined.
    // @param hash The hash of the init code to be mined.
    // @param zeros The number of leading zeros required in the solution.
    // @payable The amount of the bid.
    function submitBid(bytes32 hash, uint8 zeros) public payable {
        require(hash != 0);
        require(zeros > 0);
        require(msg.value >= expectedFee(zeros), "Insufficient bid amount.");

        bids.push(Bid(msg.sender, msg.value, hash, zeros, ""));
        emit NewBid(msg.sender, msg.value, hash, zeros);
    }

    // @dev Withdraw a bid.
    // @param index The index of the bid to withdraw.
    function withdrawBid(uint256 index) public {
        require(index < bids.length);
        Bid memory bid = bids[index];
        require(bid.bidder == msg.sender, "Only the bidder can withdraw their bid.");
        require(bid.solution == "", "Cannot withdraw a bid that has a solution.");
        payable(msg.sender).transfer(bid.amount);
        delete bids[index];
        emit BidWithdrawn(msg.sender, bid.amount, bid.hash, bid.zeros);
    }


    // @dev Get a specific bid.
    // @param index The index of the bid to get.
    // @return addr The address of the bidder.
    // @return value The amount of the bid.
    // @return hash The hash of the init code to be mined.
    // @return zeros The number of leading zeros required in the solution.
    function getBid(uint256 index) public view returns (address addr, uint256 value, bytes32 hash, uint8 zeros) {
        require(index < bids.length);
        Bid memory bid = bids[index];
        return (bid.bidder, bid.amount, bid.hash, bid.zeros);
    }


    // @dev Claim the reward for a given bid.
    // @param index The index of the bid to provide the solution for.
    // @param solution The solution to the init code hash.
    function submitSolution(uint256 index, bytes32 solution) public {
        require(index < bids.length);
        Bid storage bid = bids[index];
        require(bid.solution == "", "Solution already submitted.");
        require((address(bytes20(solution)) == bid.bidder), "Invalid solution - first 20 bytes of the salt must match bidder address.");

        address addr = addressViaHash(solution, bid.hash);
        require(addr != address(0));

        uint8 shift = 160 - (4 * bid.zeros);
        bytes20 requiredZeros = bytes20(uint160(addr) >> shift);

        require(requiredZeros == 0, "Solution does not meet the required difficulty.");
        bid.solution = solution;
        emit NewSolution(bid.bidder, msg.sender, bid.hash, solution, addr);
        payable(msg.sender).transfer(bid.amount);
    }

    // @dev Confirm the salt and init code hash for a given address.
    // @param salt The salt used to deploy the contract.
    // @param initCodeHash The hash of the init code used to deploy the contract.
    // @return deploymentAddress The expected address of the deployed contract.
    function addressViaHash(bytes32 salt, bytes32 initCodeHash) public view returns (address deploymentAddress) {
        return ImmutableCreate2Factory(CREATE2_FACTORY).findCreate2AddressViaHash(salt, initCodeHash);
    }

    // @dev Calculate the expected fee for a given number of leading zeros.
    // @param zeros The number of leading zeros required in the solution.
    // @return The expected fee for the given number of leading zeros.
    function expectedFee(uint8 zeros) public pure returns (uint256) {
        if (zeros > 4) {
            return MINIMUM_BID * (2 ** (zeros - 4));
        } else {
            return MINIMUM_BID;
        }
    }
}
