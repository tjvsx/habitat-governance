// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBase, DiamondBaseStorage, IDiamondCuttable } from "@solidstate/contracts/proxy/diamond/DiamondBase.sol";
import { OwnableStorage } from "@solidstate/contracts/access/OwnableStorage.sol";
import { RepoStorage } from "contracts/storage/RepoStorage.sol";

contract Diamond is DiamondBase {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    constructor(IDiamondCuttable.FacetCut[] memory _cuts, address _facetsRepository) {

        RepoStorage.Layout storage l = RepoStorage.layout();
        l.repo = _facetsRepository;

        DiamondBaseStorage.layout().diamondCut(_cuts, address(0), "");
        OwnableStorage.layout().owner = msg.sender;
    }
}