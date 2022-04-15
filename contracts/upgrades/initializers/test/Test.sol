// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITest } from './ITest.sol';
import { MinimalProxyFactory } from '@solidstate/contracts/factory/MinimalProxyFactory.sol';
import { TestStorage } from '../../../storage/TestStorage.sol';

import 'hardhat/console.sol';

contract Test is MinimalProxyFactory {  
    using TestStorage for TestStorage.Layout;

    event UpgradeSubmitted(address minimalProxy, bool _test);

    bool initialized;

    struct Struct {
        bool test1;
        bool test2;
    }

    function submit(Struct memory)
    external 
    returns (address)
    {
        address minimalProxy = _deployMinimalProxy(address(this));

        // ITest(minimalProxy).initialize(Struct);

        // emit UpgradeSubmitted(minimalProxy, Struct);
        return minimalProxy;
    }

    function initialize(Struct memory) 
    external 
    {
        require(!initialized, 'Upgrade Initializer: Already initialized');
        
        // // set data here
        // Struct({
        //     test1: Struct.test1,
        //     test2: Struct.test2
        // });

        initialized = true;
    }

    function init() external {
        require(initialized, 'Upgrade Initializer: Data not yet initialized');
        TestStorage.Layout storage l = TestStorage.layout();

        // set data here
        l.test = true;

    }
}


// come up with way to register arbitrary data

// ENUMERABLESET ?????