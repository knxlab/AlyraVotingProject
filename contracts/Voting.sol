// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import './VotingWorkflow.sol';
import './VotersStore.sol';
import './ProposalStore.sol';

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
    function hasEveryoneVoted() public view returns(bool) {
        return getAllProposalsVoteCount() == votersCount;
    }

    ////////
    // VOTE ADMINISTRATION
    ////////

    function registerNewVoter(address _voterAdress) public onlyOwner {
        addVoter(_voterAdress);
    }

    function openProposalRegistrationProcess() public onlyOwner registeringVoters {
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

    function getProposalById(uint _proposalId) public view onlyVoterOrOwner onlyWhenRegisteringVotersHasEnded onlyValidProposalId(_proposalId) returns(Proposal memory) {
        return proposals[_proposalId - 1];
    }

    function makeProposal(string calldata _proposalDescription) public proposalRegistrationStarted onlyVoter {
        addNewProposal(_proposalDescription);
    }

    function voteForProposal(uint _proposalId) public votingOnGoing onlyVoter onlyValidProposalId(_proposalId) {
        voters[msg.sender].votedProposalId = _proposalId;
        voters[msg.sender].hasVoted = true;
        proposals[_proposalId - 1].voteCount += 1;
        emit Voted(msg.sender, _proposalId);
    }

    function getWinner() public view onlyWhenVotesTallied returns(Proposal memory) {
        return proposals[winningProposalId];
    }
    
}