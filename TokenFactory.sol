// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;

import {IERC20} from './IERC20.sol';
import './TransferHelper.sol';

interface ITokenGen{
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
        uint256 lsfee
    ) external returns(address);
}


contract TokenFactory{

    mapping(address => address[]) tokensOwned;

    address[] tokenOwners;

    address[] generator;

    uint256[] fees;

    event TokenCreated(address);

    uint256 fee;

    address owner = 0x7534F3e7e92E8aDbA1769CB87415AedCC267abf7;

    modifier onlyOwner() {
        require(msg.sender == owner , "Not owner");
        _;
    }

    function updategenerator(uint256 i, address _generator)external onlyOwner() {
        generator[i-1] = _generator;
    }

    function updatefee(uint256 i, uint256 amt)external onlyOwner(){
        fees[i] = amt;
    }

    function selectToken(bool basic, bool std, bool ab, bool liq, bool onews, bool twows ) external pure returns(uint8){
        uint8 select;
        if(basic){select=1;}
        if(std){
            if(ab){
                if(liq){
                    if(onews){
                        select = 4;
                    } else if(twows){
                        select = 5;
                    } else {
                        select = 3;
                    }
                }
                else{
                    if(onews){
                        select = 6;
                    } else if(twows){
                        select = 7;
                    } else{
                        select = 2;
                    }
                }
            } else if (liq) {
                if(onews){
                    select = 9;
                } else if (twows){
                    select = 10;
                } else {
                    select = 8;
                }
            } else {
                if(onews){
                    select = 11;
                } else if(twows){
                    select = 12;
                } else {
                    select = 0;
                }
            }
        }
        return select;
    }

    function createToken(
        uint8 sel,
        string memory name,
        string memory symbol,
        uint8 decimals,
        uint256 totalSupply,
        uint256 w1bfee,
        uint256 w2bfee, 
        uint256 w1sfee,
        uint256 w2sfee,
        uint256 bbbfee,
        uint256 bbsfee,
        uint256 lbfee,
        uint256 lsfee,
        address raddr,
        address w1addr,
        address w2addr
        ) public payable {

        require(msg.value == fees[sel-1], "Need deployment fee");

        require(sel>0, "invalid selection");

        address space = ITokenGen(generator[sel-1]).generateToken(name, symbol, decimals, totalSupply, msg.sender, raddr, w1addr, w1bfee, w1sfee, w2addr, w2bfee, w2sfee, 
        bbbfee, bbsfee, lbfee, lsfee);

        tokenOwners.push(msg.sender);

        tokensOwned[msg.sender].push(space);

        emit TokenCreated(space);

    }

    function rescueBNB() external onlyOwner(){
        TransferHelper.safeTransferETH(owner, address(this).balance);
    }

    function transferOwnership(address newaddr)external onlyOwner(){
        owner = newaddr;
    }

}

