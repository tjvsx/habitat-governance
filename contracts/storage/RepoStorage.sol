// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// import { IDiamondCuttable } from '@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol';
import { IRepository } from "contracts/interfaces/IRepository.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";
import { EnumerableSet } from "@solidstate/contracts/utils/EnumerableSet.sol";

import "hardhat/console.sol";

library RepoStorage {
    using AddressUtils for address;
    using EnumerableSet for EnumerableSet.AddressSet;

    struct Layout {
        address repo;
        mapping(address => bool) allowedFacets;

        //upgrade => owner
        mapping(address => address) registrant;
        address[] upgrades;
    }

    bytes32 internal constant STORAGE_SLOT =
        keccak256("diamond.standard.upgrade.repo.storage");

    function layout() internal pure returns (Layout storage l) {
        bytes32 slot = STORAGE_SLOT;
        assembly {
            l.slot := slot
        }
    }

    function _isInRepo(address facet) internal view returns (bool) {
        RepoStorage.Layout storage l = RepoStorage.layout();
        if(l.allowedFacets[facet]) {
            return true;
        }
        if (l.repo != address(0)) {
            if(IRepository(l.repo).isInRepo(facet)) { 
                return true;
            }
        }
        return false;
    }

    function _setRepo(address repo) internal {
        RepoStorage.layout().repo = repo;
    }

    function _viewUpgrades() internal view returns (address[] memory) {
        return RepoStorage.layout().upgrades;
    }

    function _viewRegistrants(address[] memory upgrades) internal view returns (address[] memory) {
        RepoStorage.Layout storage l = RepoStorage.layout();
        uint length = upgrades.length;
        address[] memory registrants = new address[](length);
        for (uint i; i < upgrades.length; i++) {
            registrants[i] = l.registrant[upgrades[i]];
        }
        return registrants;
    }

    function _setUpgrade(address upgrade, address owner) internal {
        require(upgrade.isContract(), 
        "Repository: upgrade must be contract");
        RepoStorage.Layout storage l = RepoStorage.layout();
        l.registrant[upgrade] = owner;
        l.upgrades.push(upgrade);
    }
}