// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from "@solidstate/contracts/proxy/Proxy.sol";
import { OwnableStorage } from "@solidstate/contracts/access/OwnableStorage.sol";
import { IDiamondLoupe } from "@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol";

import "hardhat/console.sol";

contract DiamondProxy is Proxy {
    address private _impl;

    constructor(address implementation) {
        _impl = implementation;
        OwnableStorage.layout().owner = msg.sender;
    }

    function _getImplementation() internal view override returns (address) {
        return IDiamondLoupe(_impl).facetAddress(msg.sig);
    }
}

// contract system exists as unimplemented until it's initialized, at which point the diamond's ownership is transfered to itself and the token and governance state is set.
// in order to actually use governance, diamond must be owned by itself. in governance.executeProposal():
// require- IERC173(owner).owner() = address(this)   .....?


/// this contract may need a makeover - should be able to split away from habitat diamond at any time