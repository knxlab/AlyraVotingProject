// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;


abstract contract VotersStore {

    event VoterRegistered(address voterAddress); 

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    modifier onlyVoter {
        require(isVoter(msg.sender), "Not allowed to vote");
        _;
    }

    uint internal votersCount;
    mapping(address => Voter) internal voters;

    function isVoter(address _addr) internal view returns(bool) {
        return voters[_addr].isRegistered;
    }

    function addVoter(address _voterAddress) internal {
        voters[msg.sender].isRegistered = true;
        votersCount += 1;
        emit VoterRegistered(_voterAddress);
    }

}