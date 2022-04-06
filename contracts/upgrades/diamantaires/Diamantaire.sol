// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondCuttable } from '@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol';
import { DiamondBaseStorage } from '@solidstate/contracts/proxy/diamond/DiamondBaseStorage.sol';
import { GovernanceStorage } from '../../storage/GovernanceStorage.sol'; 

import 'hardhat/console.sol';


//   GENERAL PURPOSE DIAMANTAIRES
//   @dev: THIS CONTRACT IS TO BE CONTINUED AFTER IMMUTABLE DYNAMIC ARRAYS FEATURE ADD - https://github.com/ethereum/solidity/issues/12587 
//   -- use the numbered diamantaires (Diamantaire1.sol, Diamantaire2.sol, etc) for specific selectors[] size. 
//   Multiple facetCuts will also be supported once the immutable dynamic arrays feature is added to Solidity.


contract Diamantaire {
  using DiamondBaseStorage for DiamondBaseStorage.Layout;
  using GovernanceStorage for GovernanceStorage.Layout;

  address immutable _target;
  IDiamondCuttable.FacetCutAction immutable _action;
  bytes4[] _selectors;

  constructor(IDiamondCuttable.FacetCut[] memory _facetCuts) {
    require(_facetCuts.length == 1, "Diamantaire: Cutting multiple facets through governance is not yet supported");

    // uint selectorCount;
    
    IDiamondCuttable.FacetCut memory facetCut;
    for (uint256 i; i < _facetCuts.length; i++) { 
      facetCut = _facetCuts[i];
      _target = facetCut.target;
      _action = facetCut.action;
      // selectorCount = facetCut.selectors.length;
      
      for (uint s; s < facetCut.selectors.length; s++) {
        _selectors.push(facetCut.selectors[s]);
      }
    }
  }

  // to be delegatecalled
  function execute(uint _proposalId) external {

    IDiamondCuttable.FacetCut[] memory facetCuts = new IDiamondCuttable.FacetCut[](1);
    facetCuts[0] = IDiamondCuttable.FacetCut({
        target: _target, 
        action: _action,
        selectors: _selectors
    });

    /// @dev check if immutable dynamic array was stored
    // IDiamondCuttable.FacetCut memory facetCut;
    // for (uint256 i; i < facetCuts.length; i++) {
    //   facetCut = facetCuts[i];
    //   console.log('cutting facets to:', facetCut.target);
    //   bytes4 selector;
    //   for (uint256 s; s < facetCut.selectors.length; s++) {
    //     selector = facetCut.selectors[s];
    //     console.logBytes4(selector);
    //   }
    // }

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
