// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;


abstract contract VotersStore {

    event VoterRegistered(address voterAddress); 

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    modifier onlyAddressIsNotVoter(address _address) {
        require(isVoter(_address) == false, "Already a voter");
        _;
    }

    modifier onlyVoter {
        require(isVoter(msg.sender), "Not allowed to vote");
        _;
    }

    // No need to check if is a voter (implicit)
    modifier onlyVoterWhoHasntVoted {
        require(voterHasVoted(msg.sender), "Not allowed to vote");
        _;
    }

    uint internal votersCount;
    mapping(address => Voter) internal voters;

    function isVoter(address _addr) internal view returns(bool) {
        return voters[_addr].isRegistered == true;
    }

    function voterHasVoted(address _addr) internal view returns(bool) {
        return voters[_addr].hasVoted;
    }

    function addVoter(address _voterAddress) internal {
        voters[_voterAddress].isRegistered = true;
        votersCount += 1;
        emit VoterRegistered(_voterAddress);
    }

}