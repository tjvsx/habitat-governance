// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondCuttable } from '@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol';
import { DiamondBaseStorage } from '@solidstate/contracts/proxy/diamond/DiamondBaseStorage.sol';
import { GovernanceStorage } from '../../storage/GovernanceStorage.sol';

contract Diamantaire1 {
  using DiamondBaseStorage for DiamondBaseStorage.Layout;
  using GovernanceStorage for GovernanceStorage.Layout;

  address immutable _target;
  IDiamondCuttable.FacetCutAction immutable _action;

  bytes4 internal immutable _selector0;

  constructor(IDiamondCuttable.FacetCut[] memory _facetCuts) {
    require(_facetCuts.length == 1, "Diamantaire: Cutting multiple facets through governance is not yet supported");
    
    IDiamondCuttable.FacetCut memory facetCut;
    for (uint256 i; i < _facetCuts.length; i++) { 
      facetCut = _facetCuts[i];
      _target = facetCut.target;
      _action = facetCut.action;

      _selector0 = facetCut.selectors[0];
    }
  }

  // to be delegatecalled
  function execute(uint _proposalId) external {

    bytes4[] memory _selectors = new bytes4[](1);
    _selectors[0] = _selector0;

    IDiamondCuttable.FacetCut[] memory facetCuts = new IDiamondCuttable.FacetCut[](1);
    facetCuts[0] = IDiamondCuttable.FacetCut({
        target: _target, 
        action: _action,
        selectors: _selectors
    });

    GovernanceStorage.Layout storage gs = GovernanceStorage.layout();
    GovernanceStorage.Proposal storage p = gs.proposals[_proposalId];

    address initializer = p.initializer;
    bytes memory data = abi.encodeWithSignature('init()');

    DiamondBaseStorage.layout().diamondCut(facetCuts, initializer, data); 
  }
}