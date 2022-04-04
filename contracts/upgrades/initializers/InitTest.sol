// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { TestStorage } from '../../storage/TestStorage.sol';

import 'hardhat/console.sol';

contract InitTest {  
    using TestStorage for TestStorage.Layout; 
    function init() external {
        // declaring storage
        TestStorage.Layout storage l = 
        TestStorage.layout();
        l.test = true;
    }
}