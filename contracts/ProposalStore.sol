// SPDX-License-Identifier: GPL-3.0

pragma solidity 0.8.17;

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

    modifier onWhenProposalNotEmpty {
        require(proposals.length > 0, "List of proposal is empty");
        _;
    }

    Proposal[] internal proposals;

    // Returns zero (0) if proposal desc does not exists
    function getProposalIdFromDesc(string calldata _proposalDescription) internal view returns(uint) {

        for (uint i = 0; i < proposals.length; i++) {
            if (keccak256(abi.encodePacked(proposals[i].description)) == keccak256(abi.encodePacked(_proposalDescription))) {
                return i + 1;
            }
        }

        return 0;
    }

    /**
     * Add a new proposal in the store
     */ 
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