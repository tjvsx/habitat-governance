// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
interface ITest {
  
    function submit(bool) external returns (address);

    function initialize(bool) external;

    function init() external;
}
