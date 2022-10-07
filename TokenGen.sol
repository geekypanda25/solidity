// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {ERC20} from './ERC20.sol'; 

contract TokenGen{

    modifier onlyFactory() {
        require(msg.sender == factory , "Not owner");
        _;
    }

    address factory = 0xDF9d2b0f340A2bF8dEbFd2b6f9D5d37e0985c8bc;



    function generateToken(
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        address owner,
        address raddr,
        address maddr,
        uint256 mbfee,
        uint256 msfee,
        address daddr,
        uint256 dbfee, 
        uint256 dsfee,
        uint256 bbbfee,
        uint256 bbsfee,
        uint256 lbfee,
        uint256 lsfee)external onlyFactory() returns(address){

        ERC20 newtok = new ERC20(name, symbol);

        return address(newtok);

    }

}