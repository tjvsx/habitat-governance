// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { Proxy } from "@solidstate/contracts/proxy/Proxy.sol";
import { OwnableStorage } from "@solidstate/contracts/access/OwnableStorage.sol";
import { IDiamondLoupe } from "@solidstate/contracts/proxy/diamond/IDiamondLoupe.sol";

import 'hardhat/console.sol';

contract DiamondProxy is Proxy {
    address private _impl;

    constructor(address implementation) {
        _impl = implementation;
        OwnableStorage.layout().owner = msg.sender;
    }

    // change implementation address
    // function upgrade(address implementation) external onlyOwner {}

    function _getImplementation() internal view override returns (address) {
        return IDiamondLoupe(_impl).facetAddress(msg.sig);
    }
}