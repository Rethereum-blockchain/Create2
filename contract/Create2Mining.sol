// SPDX-License-Identifier: GPL-2
pragma solidity ^0.8.0;

interface ImmutableCreate2Factory {
    function findCreate2AddressViaHash(bytes32 salt, bytes32 initCodeHash) external view returns (address deploymentAddress);
}

contract Create2Mining {

    uint256 public constant MINIMUM_BID = 10 ether;
    address public constant CREATE2_FACTORY = 0x00000000000e974Fb8B2985Eb2fda6Dd13b90ACb;

    struct Bid {
        address bidder;
        uint256 amount;
        bytes32 hash;
        uint8 zeros;
        bytes32 solution;
    }

    Bid[] public bids;

    function submitBid(bytes32 hash, uint8 zeros) public payable {
        require(hash != 0);
        require(zeros > 0);

        if (zeros > 4) {
            uint256 amount = MINIMUM_BID * (2 ** (zeros - 4));
            require(msg.value >= amount);
        } else {
            require(msg.value >= MINIMUM_BID);
        }

        bids.push(Bid(msg.sender, msg.value, hash, zeros, ""));
    }


    function getBid(uint256 index) public view returns (address addr, uint256 value, bytes32 hash, uint8 zeros) {
        require(index < bids.length);
        Bid memory bid = bids[index];
        return (bid.bidder, bid.amount, bid.hash, bid.zeros);
    }

    function submitSolution(uint256 index, bytes32 solution) public {
        require(index < bids.length);
        Bid memory bid = bids[index];
        require((address(bytes20(solution)) == bid.bidder), "Invalid solution - first 20 bytes of the salt must match bidder address.");

        address factory = address(CREATE2_FACTORY);
        address addr = ImmutableCreate2Factory(factory).findCreate2AddressViaHash(solution, bid.hash);
        require(addr != address(0));

        uint8 solutionZeros = 0;
        for (uint8 i = 0; i < 20; i++) {
            if (uint8(solution[i]) >> 4 == 0) {
                solutionZeros++;
            } else {
                break;
            }
        }

        require(solutionZeros >= bid.zeros, "Solution does not meet the required difficulty.");
        bid.solution = solution;

        payable(msg.sender).transfer(bid.amount);
    }
}
