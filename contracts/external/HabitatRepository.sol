// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { IRepository } from "contracts/interfaces/IRepository.sol";
import { AddressUtils } from "@solidstate/contracts/utils/AddressUtils.sol";

contract HabitatRepository is IRepository {
    using AddressUtils for address;

    address owner;
    mapping(address => bool) facets;
    // initializer => upgrade contract
    mapping(address => address) upgrade;

    constructor(
      address _owner, 
      address[] memory  _addresses) 
    {
        owner = _owner;
        for (uint i = 0; i < _addresses.length; i++) {
            facets[_addresses[i]] = true;
        }
    }
    function edit(
      address facet, 
      bool value) 
    external {
        require(owner == address(msg.sender), "Only owner can write repo");
        facets[facet] = value;
    }
    function isInRepo(
      address facet) 
    view external returns (bool) {
        if (facets[facet]) {
          return true;
        }
        return false;
    }
}