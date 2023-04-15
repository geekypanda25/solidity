// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {IGovernor} from './IGovernor.sol';
import {PYEGov} from './Governor.sol';

contract GovFactory{

    mapping(address => address) spaces;

    uint256 deployed = 0;

    event SpaceCreated(address, address);

    function createSpace(address _tokenaddr ,bool _snap) public returns(address space){
        require(spaces[_tokenaddr]==address(0x0),"Space already exists for token");
         
        bytes memory bytecode = type(PYEGov).creationCode;
        
        bytes32 salt = keccak256(abi.encodePacked(_tokenaddr));
        
        assembly{
         
            space := create2(0, add(bytecode, 32), mload(bytecode), salt)
        
        }
        
        spaces[_tokenaddr] = space;
        
        IGovernor(space).init(_tokenaddr, _snap);
        
        emit SpaceCreated(_tokenaddr, space);

        deployed++;
    }

    function numdeployed() external view returns (uint256){return deployed;}

}

