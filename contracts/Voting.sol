// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

import 'https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/access/Ownable.sol';
import './VotingWorkflow.sol';
import './VotersStore.sol';
import './ProposalStore.sol';
import './DonateToChildrenCancerAssoc.sol';


contract Voting is Ownable, VotersStore, ProposalStore, VotingWorkflow, DonateToChildrenCancerAssoc {

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

    function registerNewVoter(address _voterAdress) public onlyOwner onlyIfAddressIsNotVoter(_voterAdress) onlyWhenRegisteringVoters {
        addVoter(_voterAdress);
    }

    function openProposalRegistrationProcess() public onlyOwner onlyWhenRegisteringVoters {
        require(votersCount > 0, "You need to add at least 1 voters");
        setNewWorkflowStatus(WorkflowStatus.ProposalsRegistrationStarted);
    }
    function closeProposalRegistrationProcess() public 
             onlyOwner onlyWhenProposalRegistrationStarted 
             onWhenProposalNotEmpty {
        setNewWorkflowStatus(WorkflowStatus.ProposalsRegistrationEnded);
    }

    function openVotingSession() public onlyOwner onlyWhenProposalRegistrationEnded {
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
     * Return the proposal description
     */ 
    function getProposalVoteCountById(uint _proposalId) public view onlyVoterOrOwner onlyWhenRegisteringVotersHasEnded onlyValidProposalId(_proposalId) returns(uint) {
        return proposals[_proposalId - 1].voteCount;
    }

    /**
     * Make a new proposal - only for voters
     * A voter can make multiple proposal
     * "Les électeurs inscrits sont autorisés à enregistrer leurs propositions" => "propositions" au pluriel :)
     */ 
    function makeProposal(string calldata _proposalDescription) public onlyWhenProposalRegistrationStarted onlyVoter {
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
     * Get vote for voter
     */
    function getVoteBy(address _voter) public view onlyAfterVotingStarted onlyIfAddressIsVoter(_voter) onlyVoterOrOwner returns(uint) {
        return winningProposalId;
    }


    ////////
    // PUBLIC ACTIONS
    ////////

    /**
     * L'enoncé étant ambigue, ces functions sont publiques
     * "Tout le monde peut vérifier les derniers détails de la proposition gagnante."
     * "Tout le monde" peut vouloir dire "publiquement accessible" ou 
     * "Accessible aux voter + administrateur"
     * 
     * S'il fallait le rendre accesible qu'aux voter + admin 
     * Il faudrait ajouter le modifier "onlyVoterOrOwner" défini plus haut
     * 
     */

    /**
     * Get the winner proposal
     */
    function getWinnerProposal() public view onlyWhenVotesTallied returns(Proposal memory) {
        return proposals[winningProposalId - 1];
    }

    /**
     * Get the winner proposal id
     */
    function getWinner() public view onlyWhenVotesTallied returns(uint) {
        return winningProposalId;
    }
    
}