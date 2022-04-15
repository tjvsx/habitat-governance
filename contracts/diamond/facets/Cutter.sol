// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondCuttable } from '@solidstate/contracts/proxy/diamond/DiamondCuttable.sol';

contract Cutter is DiamondCuttable {
    receive() external payable {}
}