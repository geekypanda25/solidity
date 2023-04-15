// SPDX-License-Identifier: MIT

pragma solidity ^0.8.17;

import "hardhat/console.sol";
import "../GovFactory.sol";

contract tester {
    GovFactory factory;

    function runandcheck() public {
        Assert.equal(factory.numdeploed(),uint256(0),"should be 0");
    }
}

