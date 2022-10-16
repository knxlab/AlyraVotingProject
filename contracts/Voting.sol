// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import './VotingWorkflow.sol';
import './VotersStore.sol';
import './ProposalStore.sol';

/*
Remix VM (London) Tests :

Owner:
0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

Voters :
0xAb8483F64d9C6d1EcF9b849Ae677dD3315835cb2
0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db
0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB
0x617F2E2fD72FD9D5503197092aC168c91465E7f2
*/

contract Voting is Ownable, VotersStore, ProposalStore, VotingWorkflow {

    struct Statistics {
        uint voteSessionStartedAt;
        uint voteSessionEndedAt;
        uint totalVoters;
        uint totalVotes;
    }

    modifier onlyVoterOrOwner {
        require(owner() == msg.sender || isVoter(msg.sender), "You must be the owners of one of the voters");
        _;
    }
    
    event Voted (address voter, uint proposalId);

    uint private winningProposalId;
    Statistics private statistics;

    ////////
    // UTILS
    ////////
    function hasEveryoneVoted() internal view returns(bool) {
        return getAllProposalsVoteCount() == votersCount;
    }

    ////////
    // VOTE ADMINISTRATION
    ////////

    function registerNewVoter(address _voterAdress) public onlyOwner onlyAddressIsNotVoter(_voterAdress) {
        addVoter(_voterAdress);
    }

    function openProposalRegistrationProcess() public onlyOwner registeringVoters {
        require(votersCount > 0, "You need to add at least 1 voters");
        setNewWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted);
    }
    function closeProposalRegistrationProcess() public onlyOwner proposalRegistrationStarted {
        setNewWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded);
    }

    function openVotingSession() public onlyOwner proposalRegistrationEnded {
        setNewWorkflowStatus(WorkflowStatus.VotingSessionStarted);
    }
    function closeVotingSession() public onlyOwner votingOnGoing {
        require(hasEveryoneVoted(), "Warning: Some people haven t voted yet ! Use closeVotingSession(force = true) to force close");
        setNewWorkflowStatus(WorkflowStatus.VotingSessionEnded);
    }
    function closeVotingSession(bool _force) public onlyOwner votingOnGoing {
        require(_force, "You can only use it with force == true");
        setNewWorkflowStatus(WorkflowStatus.VotingSessionEnded);
    }

    function processVote() public onlyOwner votingEnded {
        winningProposalId = getFirstProposalIdWithMaxVotes();

        statistics.voteSessionStartedAt = votingSessionStartedAt;
        statistics.voteSessionEndedAt = votingSessionEndedAt;
        statistics.totalVoters = votersCount;
        statistics.totalVotes = getAllProposalsVoteCount();
        setNewWorkflowStatus(WorkflowStatus.VotesTallied);
    }

    ////////
    // VOTERS ACTIONS
    ////////

    /**
     * Return the proposal description
     */ 
    function getProposalDescById(uint _proposalId) public view onlyVoterOrOwner onlyWhenRegisteringVotersHasEnded onlyValidProposalId(_proposalId) returns(string memory) {
        return proposals[_proposalId - 1].description;
    }

    /**
     * Make a new proposal - only for voters
     */ 
    function makeProposal(string calldata _proposalDescription) public proposalRegistrationStarted onlyVoter {
        addNewProposal(_proposalDescription);
    }

    /**
     * vote for a proposal - only for voters who hasn't voted yet
     */
    function voteForProposal(uint _proposalId) public votingOnGoing onlyVoterWhoHasntVoted onlyValidProposalId(_proposalId) {
        voters[msg.sender].votedProposalId = _proposalId;
        voters[msg.sender].hasVoted = true;
        proposals[_proposalId - 1].voteCount += 1;
        emit Voted(msg.sender, _proposalId);
    }

    /**
     * Get the winner proposal
     */
    function getWinner() public view onlyWhenVotesTallied returns(Proposal memory) {
        return proposals[winningProposalId];
    }
    
}