// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondCuttable } from '@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol';
import { DiamondBaseStorage } from '@solidstate/contracts/proxy/diamond/DiamondBaseStorage.sol';
import { GovernanceStorage } from '../../storage/GovernanceStorage.sol';

contract Diamantaire5 {
  using DiamondBaseStorage for DiamondBaseStorage.Layout;
  using GovernanceStorage for GovernanceStorage.Layout;

  address immutable _target;
  IDiamondCuttable.FacetCutAction immutable _action;

  bytes4 internal immutable _selector0;
  bytes4 internal immutable _selector1;
  bytes4 internal immutable _selector2;
  bytes4 internal immutable _selector3;
  bytes4 internal immutable _selector4;

  constructor(IDiamondCuttable.FacetCut[] memory _facetCuts) {
    require(_facetCuts.length == 1, "Diamantaire: Cutting multiple facets through governance is not yet supported");
    
    IDiamondCuttable.FacetCut memory facetCut;
    for (uint256 i; i < _facetCuts.length; i++) { 
      facetCut = _facetCuts[i];
      _target = facetCut.target;
      _action = facetCut.action;

      _selector0 = facetCut.selectors[0];
      _selector1 = facetCut.selectors[1];
      _selector2 = facetCut.selectors[2];
      _selector3 = facetCut.selectors[3];
      _selector4 = facetCut.selectors[4];
    }
  }

  // to be delegatecalled
  function execute(uint256 _proposalId) external {

    bytes4[] memory _selectors = new bytes4[](5);
    _selectors[0] = _selector0;
    _selectors[1] = _selector1;
    _selectors[2] = _selector2;
    _selectors[3] = _selector3;
    _selectors[4] = _selector4;

    IDiamondCuttable.FacetCut[] memory facetCuts = new IDiamondCuttable.FacetCut[](1);
    facetCuts[0] = IDiamondCuttable.FacetCut({
        target: _target, 
        action: _action,
        selectors: _selectors
    });

    GovernanceStorage.Layout storage gs = GovernanceStorage.layout();
    GovernanceStorage.Proposal storage p = gs.proposals[_proposalId];

    address initializer;
    bytes memory data;
    if (p.initializer != address(0)) {
      initializer = p.initializer;
      data = abi.encodeWithSignature('init()');
    }

    DiamondBaseStorage.layout().diamondCut(facetCuts, initializer, data); 
  }
}