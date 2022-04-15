// contracts/utils/EnumerableSet.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import { ITest } from './ITest.sol';
import { MinimalProxyFactory } from '@solidstate/contracts/factory/MinimalProxyFactory.sol';
import { TestStorage } from '../../../storage/TestStorage.sol';
import { EnumerableSet } from '@solidstate/contracts/utils/EnumerableSet.sol';

import 'hardhat/console.sol';

contract SubmitTest is MinimalProxyFactory {  
    using TestStorage for TestStorage.Layout;

    event UpgradeSubmitted(address minimalProxy, bool _test);

    bool initialized;

    function submit(
      EnumerableSet.Set memory
    )
    external 
    returns (address)
    {
        address minimalProxy = _deployMinimalProxy(address(this));
        uint length = EnumerableSet.Set;
        for (uint i; i < length; i++) {
          EnumerableSet.add();
        }

        ITest(minimalProxy).initialize(EnumerableSet.Set);

        // emit UpgradeSubmitted(minimalProxy, Struct);
        return minimalProxy;
    }

    function initialize(EnumerableSet.Set memory) 
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