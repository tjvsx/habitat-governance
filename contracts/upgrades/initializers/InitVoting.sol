// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ERC20BaseInternal } from '@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol';
import { ERC20MetadataStorage } from '@solidstate/contracts/token/ERC20/metadata/ERC20MetadataStorage.sol';
import { ERC20BaseStorage } from '@solidstate/contracts/token/ERC20/base/ERC20BaseStorage.sol';
import { GovernanceStorage } from '../../storage/GovernanceStorage.sol'; 

contract InitVoting is ERC20BaseInternal {  
    using ERC20MetadataStorage for ERC20MetadataStorage.Layout;
    using ERC20BaseStorage for ERC20BaseStorage.Layout;  
    function init() external {
        // declaring storage
        ERC20MetadataStorage.Layout storage t = 
        ERC20MetadataStorage.layout();
        GovernanceStorage.Layout storage g = 
        GovernanceStorage.layout();

        t.setName("Token");
        t.setSymbol("TKN");
        t.setDecimals(8);

        _mint(msg.sender, 1000);

        // Require 5 percent of governance token for votes to pass a proposal
        g.quorumDivisor = 20;
        // Proposers must own 1 percent of totalSupply to submit a proposal
        g.proposalThresholdDivisor = 100;
        // Proposers get an additional 5 percent of their balance if their proposal passes
        g.proposerAwardDivisor = 20;
        // Voters get an additional 1 percent of their balance for voting on a proposal
        g.voterAwardDivisor = 100;
        // Cap voter and proposer balance used to generate awards at 5 percent of totalSupply
        // This is to help prevent too much inflation
        g.voteAwardCapDivisor = 20;
        // Proposals must have at least 48 hours of voting time
        // g.minDuration = 48;
        // Proposals must have no more than 336 hours (14 days) of voting time
        g.maxDuration = 336;
    }


}