// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';

abstract contract VotingWorkflow {

    enum WorkflowStatus {
        RegisteringVoters,
        ProposalsRegistrationStarted,
        ProposalsRegistrationEnded,
        VotingSessionStarted,
        VotingSessionEnded,
        VotesTallied
    }
    event WorkflowStatusChange(WorkflowStatus previousStatus, WorkflowStatus newStatus);

    WorkflowStatus internal currentWorkflowStatus = WorkflowStatus.RegisteringVoters;
    uint internal votingSessionStartedAt;
    uint internal votingSessionEndedAt;

    modifier votingOnGoing {
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionStarted, "Voting session not started or has ended");
        _;
    }

    modifier votingEnded {
        require(currentWorkflowStatus == WorkflowStatus.VotingSessionEnded, "Voting session not started or has not ended");
        _;
    }

    modifier proposalRegistrationStarted {
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationStarted, "Proposal registration not started or has ended");
        _;
    }

    modifier proposalRegistrationEnded {
        require(currentWorkflowStatus == WorkflowStatus.ProposalsRegistrationEnded, "Proposal registration not started or not ended");
        _;
    }

    modifier registeringVoters {
        require(currentWorkflowStatus == WorkflowStatus.RegisteringVoters, "Voter registration already ended");
        _;
    }

    modifier onlyWhenRegisteringVotersHasEnded {
        require(currentWorkflowStatus > WorkflowStatus.RegisteringVoters, "Voter registration has not ended");
        _;
    }

    function setNewWorkflowStatus(WorkflowStatus _newStatus) internal {
        WorkflowStatus previousWorkflowStatus = currentWorkflowStatus;
        currentWorkflowStatus = _newStatus;

        if (_newStatus == WorkflowStatus.VotingSessionStarted) {
            votingSessionStartedAt = block.timestamp;
        } else if (_newStatus == WorkflowStatus.VotingSessionEnded) {
            votingSessionEndedAt = block.timestamp;
        }

        emit WorkflowStatusChange(previousWorkflowStatus, currentWorkflowStatus);
        
    }

}

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

abstract contract ProposalStore {

    event ProposalRegistered(uint proposalId);
    struct Proposal {
        string description;
        uint voteCount;
    }

    // first _proposalId must be 1, in order to make it more human friendly
    modifier onlyValidProposalId(uint _proposalId) {
        require(_proposalId > 0 && _proposalId <= proposals.length, "Proposal does not exists");
        _;
    }
    
    modifier onlyNotExistingProposal(string calldata _proposalDescription) {
        require(getProposalIdFromDesc(_proposalDescription) == 0, "This proposal already exists !");
        _;
    }

    Proposal[] public proposals;

    // Returns zero (0) if proposal desc does not exists
    function getProposalIdFromDesc(string calldata _proposalDescription) internal view returns(uint) {

        for (uint i = 0; i < proposals.length; i++) {
            if (keccak256(abi.encodePacked(proposals[i].description)) == keccak256(abi.encodePacked(_proposalDescription))) {
                return i + 1;
            }
        }

        return 0;
    }

    function addNewProposal(string calldata _proposalDescription) internal onlyNotExistingProposal(_proposalDescription) {
        proposals.push(Proposal(_proposalDescription, 0));
        emit ProposalRegistered(proposals.length);
    }

    function getAllProposalsVoteCount() internal view returns(uint) {
        uint voteCount = 0;
        for (uint i = 0; i < proposals.length; i++) {
            voteCount += proposals[i].voteCount;
        }

        return voteCount;
    }

    function getFirstProposalIdWithMaxVotes() internal view returns(uint) {
        uint proposalId = 1;
        for (uint i = 1; i < proposals.length; i++) {
            if (proposals[i].voteCount > proposals[proposalId - 1].voteCount) {
                proposalId = i + 1;
            }
        }

        return proposalId;
    }
}

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

    function getWinner() public view returns(Proposal memory) {
        return proposals[winningProposalId];
    }
    
}