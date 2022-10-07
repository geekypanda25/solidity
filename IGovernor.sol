// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

interface IGovernor {

    event initialize(address token);

    event newproposal(uint256, string);

    event Vote(bool, uint256);

    function vote(bool vote, uint256 prop) external;

    function initprop(string memory , uint256) external;

    function init(address tokenaddr, bool selsnap) external;

    function combineWeight(address del) external;

}