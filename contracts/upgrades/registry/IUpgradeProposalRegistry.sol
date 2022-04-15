// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import { IDiamondCuttable } from '@solidstate/contracts/proxy/diamond/IDiamondCuttable.sol';
interface IUpgradeProposalRegistry is IDiamondCuttable {

    event UpgradeProposalRegistered (address minimalProxy, IDiamondCuttable.FacetCut[] facetCuts);

    function setUpgrade(FacetCut[] memory _facetCuts) external;

    function getUpgrade() external view returns (IDiamondCuttable.FacetCut[] memory);

    function execute(uint256 _proposalId) external;
}
