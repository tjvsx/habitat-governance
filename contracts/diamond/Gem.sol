// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondBase, DiamondBaseStorage, IDiamondCuttable } from '@solidstate/contracts/proxy/diamond/DiamondBase.sol';
import { OwnableStorage } from "@solidstate/contracts/access/OwnableStorage.sol";

contract Gem is DiamondBase {
    using DiamondBaseStorage for DiamondBaseStorage.Layout;

    constructor(IDiamondCuttable.FacetCut[] memory cuts) {
        DiamondBaseStorage.layout().diamondCut(cuts, address(0), '');
        OwnableStorage.layout().owner = msg.sender;
    }
}