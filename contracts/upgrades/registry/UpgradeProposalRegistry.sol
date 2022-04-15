// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondCuttable } from '@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol';
import { DiamondBaseStorage } from '@solidstate/contracts/proxy/diamond/DiamondBaseStorage.sol';
import { GovernanceStorage } from '../../storage/GovernanceStorage.sol';
import { MinimalProxyFactory } from '@solidstate/contracts/factory/MinimalProxyFactory.sol';
import { IUpgradeProposalRegistry } from './IUpgradeProposalRegistry.sol';

contract UpgradeProposalRegistry is MinimalProxyFactory {
  using DiamondBaseStorage for DiamondBaseStorage.Layout;
  using GovernanceStorage for GovernanceStorage.Layout;

  event UpgradeProposalRegistered (address minimalProxy, IDiamondCuttable.FacetCut[] facetCuts);

  bool registered;

  struct Cut {
    address target;
    IDiamondCuttable.FacetCutAction action;
    bytes4[] selectors;
  }

  Cut[] public cuts;

  function register(IDiamondCuttable.FacetCut[] memory _facetCuts) 
  external 
  returns (address) 
  {
    address minimalProxy = _deployMinimalProxy(address(this));
    IUpgradeProposalRegistry(minimalProxy).setUpgrade(_facetCuts);

    emit UpgradeProposalRegistered(minimalProxy, _facetCuts);

    return minimalProxy;
  }

  function setUpgrade(IDiamondCuttable.FacetCut[] memory _facetCuts) 
  external 
  {
    require(!registered, 'UpgradeProposalRegistry: Contract already initialized, you cannot change its state');
    IDiamondCuttable.FacetCut memory facetCut;
    for (uint256 i; i < _facetCuts.length; i++) { 
      facetCut = _facetCuts[i];
      cuts.push(Cut(facetCut.target, facetCut.action, facetCut.selectors));
    }

    registered = true;
  }

  function getUpgrade() 
  external 
  view 
  returns (IDiamondCuttable.FacetCut[] memory) 
  {
    uint length = cuts.length;
    IDiamondCuttable.FacetCut[] memory facetCuts = new IDiamondCuttable.FacetCut[](length);
    for (uint i; i < facetCuts.length; i++) {
      facetCuts[i] = IDiamondCuttable.FacetCut({
          target: cuts[i].target, 
          action: cuts[i].action,
          selectors: cuts[i].selectors
      });
    }
    return facetCuts;
  }

  // to be delegatecalled
  function execute(uint256 _proposalId) 
  external 
  {

    GovernanceStorage.Layout storage gs = GovernanceStorage.layout();
    GovernanceStorage.Proposal storage p = gs.proposals[_proposalId];

    address proposalContract = p.proposalContract;
    address initializer;
    bytes memory data;
    if (p.initializer != address(0)) {
      initializer = p.initializer;
      data = abi.encodeWithSignature('init()');
    }

    IDiamondCuttable.FacetCut[] memory facetCuts = IUpgradeProposalRegistry(proposalContract).getUpgrade();

    DiamondBaseStorage.layout().diamondCut(facetCuts, initializer, data); 
  }
}