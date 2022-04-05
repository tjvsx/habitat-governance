// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { ERC20BaseInternal } from '@solidstate/contracts/token/ERC20/base/ERC20BaseInternal.sol';

contract TokenMinter is ERC20BaseInternal {

  //basically a callback function
  function execute(uint _proposalId) external {
    // peform an operation on the storage of the contract that's calling it
    if (_proposalId >= 0) {
      _mint(msg.sender, 500);
    }
  }
}

/* 
with this approach, we can have a set of external proposal contracts,
each with the execute() function with a specific functionality,
whether that functionality is minting, burning, transfering, cutting in/out facets, etc  

the diamond is callable in a specific way (no function collisions allowed), 
but the diamond can call other contracts in an arbitrary way, 
so function selectors can be preset in a call within the diamond's facet (ex: governance.execute()) 
and calling it can lead to many different functionalities. 
-- with this, must consider possible security issues and whether it's gas-optimal
*/
