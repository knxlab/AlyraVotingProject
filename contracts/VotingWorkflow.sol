// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.13;

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

    modifier onlyWhenVotesTallied {
        require(currentWorkflowStatus == WorkflowStatus.VotesTallied, "Votes has not been tallied yet");
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