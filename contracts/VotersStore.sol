// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;


abstract contract VotersStore {

    event VoterRegistered(address voterAddress); 

    struct Voter {
        bool isRegistered;
        bool hasVoted;
        uint votedProposalId;
    }

    modifier onlyIfAddressIsNotVoter(address _address) {
        require(isVoter(_address) == false, "Already a voter");
        _;
    }

    modifier onlyIfAddressIsVoter(address _address) {
        require(isVoter(_address) == true, "Not a voter");
        _;
    }

    modifier onlyVoter {
        require(isVoter(msg.sender), "Not allowed to vote");
        _;
    }

    modifier onlyVoterWhoHasntVoted {
        require(isVoter(msg.sender) && voterHasVoted(msg.sender) == false, "Not allowed to vote");
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