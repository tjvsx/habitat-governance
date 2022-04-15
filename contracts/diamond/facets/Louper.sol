// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { DiamondLoupe } from '@solidstate/contracts/proxy/diamond/DiamondLoupe.sol';

contract Louper is DiamondLoupe {
    receive() external payable {}
}