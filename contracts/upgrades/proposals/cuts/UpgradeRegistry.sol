// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondCuttable } from "@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol";
import { DiamondBaseStorage } from "@solidstate/contracts/proxy/diamond/DiamondBaseStorage.sol";
import { MinimalProxyFactory } from "@solidstate/contracts/factory/MinimalProxyFactory.sol";
import { GovernanceStorage } from "contracts/storage/GovernanceStorage.sol";
import { IUpgradeRegistry } from "contracts/interfaces/IUpgradeRegistry.sol";
import { RepoStorage } from "contracts/storage/RepoStorage.sol";

import 'hardhat/console.sol';

contract UpgradeRegistry is MinimalProxyFactory {

  using DiamondBaseStorage for DiamondBaseStorage.Layout;
  using GovernanceStorage for GovernanceStorage.Layout;

  event UpgradeRegistered (
    address diamond,
    address upgrade, 
    IDiamondCuttable.FacetCut[] _facetCuts, 
    address _target, 
    bytes _data
  );

  bool private registered;
  address public owner;

  struct Cut {
    address target;
    IDiamondCuttable.FacetCutAction action;
    bytes4[] selectors;
  }

  Cut[] public cuts;
  address public target;
  bytes public data;

  function register(
    address _owner,
    IDiamondCuttable.FacetCut[] memory _facetCuts, 
    address _target, 
    bytes calldata _data) 
  external returns (address) {
    //require(address(this).isContract(), "UpgradeRegistry: Registrant(s) should be multisig");
    address _upgrade = _deployMinimalProxy(address(this));
    IUpgradeRegistry(_upgrade).set(_owner,_facetCuts, _target, _data);

    emit UpgradeRegistered(_owner, _upgrade, _facetCuts, _target, _data);
    return _upgrade;
  }

  function set(
    address _owner,
    IDiamondCuttable.FacetCut[] memory _facetCuts, 
    address _target, 
    bytes calldata _data) 
  external {
    require(!registered, 
    "UpgradeProposalRegistry: Upgrade already registered, you cannot change its state");
    owner = _owner;
    IDiamondCuttable.FacetCut memory facetCut;
    for (uint256 i; i < _facetCuts.length; i++) { 
      facetCut = _facetCuts[i];
      cuts.push(Cut(facetCut.target, facetCut.action, facetCut.selectors));
    }
    target = _target;
    data = _data;
    registered = true;
  }

  function get() 
  external view returns (address, IDiamondCuttable.FacetCut[] memory, address, bytes memory) {
    uint length = cuts.length;
    IDiamondCuttable.FacetCut[] memory facetCuts = new IDiamondCuttable.FacetCut[](length);
    for (uint i; i < facetCuts.length; i++) {
      facetCuts[i] = IDiamondCuttable.FacetCut({
          target: cuts[i].target, 
          action: cuts[i].action,
          selectors: cuts[i].selectors
      });
    }
    return(owner, facetCuts, target, data);
  }

  function execute(uint256 _proposalId) external {
    GovernanceStorage.Layout storage l = GovernanceStorage.layout();
    GovernanceStorage.Proposal storage p = l.proposals[_proposalId];

    address upgrade = p.proposalContract;

    (address __owner, IDiamondCuttable.FacetCut[] memory facetCuts, address __target, bytes memory __data) = 
    IUpgradeRegistry(upgrade).get();

    //require(address(this) owns NFT)
    DiamondBaseStorage.layout().diamondCut(facetCuts, __target, __data);

    RepoStorage._setUpgrade(upgrade, __owner);
  }
}




