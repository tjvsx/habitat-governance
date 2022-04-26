// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBaseStorage } from "@solidstate/contracts/proxy/diamond/DiamondBaseStorage.sol";
import { OwnableInternal } from "@solidstate/contracts/access/OwnableInternal.sol";
import { IDiamondCuttable } from "@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol";
import { DiamondCuttable } from "@solidstate/contracts/proxy/diamond/DiamondCuttable.sol";
import { RepoStorage } from "contracts/storage/RepoStorage.sol";


contract DiamondCutFacet is IDiamondCuttable, OwnableInternal {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    modifier onlyRepo(FacetCut[] calldata facetCuts, address target) {
        for (uint256 i; i < facetCuts.length; i++) {
            require(RepoStorage._isInRepo(facetCuts[i].target), 
            "Facet not in repo :/");
        }
        _;
    }

    // function setRepo(address repo) external {
    //     RepoStorage._setRepo(repo);
    // }

    // function setUpgrade() external {
    //     RepoStorage._setUpgrade(repo, initializers, upgrades);
    // }

    function diamondCut(
        FacetCut[] calldata facetCuts,
        address target,
        bytes calldata data
    ) external onlyOwner /* onlyRepo(facetCuts, target) */ returns (bool) {
        DiamondBaseStorage.layout().diamondCut(facetCuts, target, data);
    }
    receive() external payable {}
}