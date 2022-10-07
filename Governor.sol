// SPDX-License-Identifier: MIT

pragma solidity ^0.8.14;



import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface IGov is IERC20 {

    function balanceOf(address account) external view returns (uint256);

    function snapshot() external returns (uint256);

    function balanceOfAt(address account, uint256 snapshotId) external view virtual returns (uint256);

    function totalSupply() external view returns (uint256);

    function totalSupplyAt(uint256 snapshotId) external view virtual returns (uint256);

    function getCurrentSnapshotId() external view returns (uint256);

}

contract PYEGov{

    address public tokenaddress;

    //address factory = 0x2Ac164e7D2B38e4f853FEC79e2bFd453E1B3201C;

    struct Proposal{

        uint256 createdtime;

        uint256 endtime;

        uint256 votesreceived;

        uint256 votesfor;

        uint256 votesagainst;

        mapping(address => bool) voted; 

        string proposal;

        uint256 snapId;

    }

    mapping(uint256 => Proposal) propID;

    struct Weights{

        mapping(address => uint256) delegated;

        address[] delegators;

        uint256 votes;
    } 

    mapping(address => Weights) weight;

    bool snap;

    bool inited;

    uint256 currprop = 0;

    event initialize(address token);

    event newproposal(uint256, string);

    event Vote(bool, uint256);

    function getWeight(uint256 _prop) internal returns (uint256){

        if(snap){
        
            weight[msg.sender].votes = IGov(tokenaddress).balanceOfAt(msg.sender, propID[_prop].snapId);
        
        }
        else{
        
            weight[msg.sender].votes = IGov(tokenaddress).balanceOf(msg.sender);
        
        }

        return weight[msg.sender].votes;
    }

    function getSupply(uint256 id) internal returns (uint256){
        uint256 sup;
        if(snap){
        
            sup = IGov(tokenaddress).totalSupplyAt(id);
        
        }
        else{
        
            sup = IGov(tokenaddress).totalSupply();
        
        }

        return sup;
    }

    function vote(bool myvote, uint256 prop) public {
        require( propID[prop].endtime > block.timestamp, "Voting ended" );
        
        require( propID[prop].voted[msg.sender]!= true, "Already voted");

        getWeight(prop);

        if(myvote){
        
            propID[prop].votesfor = weight[msg.sender].votes;
        
            propID[prop].votesreceived = weight[msg.sender].votes;
        
        }
        
        else{
        
            propID[prop].votesagainst = weight[msg.sender].votes;

            propID[prop].votesreceived = weight[msg.sender].votes;
        
        }
        
        propID[prop].voted[msg.sender] = true;
        
        emit Vote(myvote, prop);
    }

    function initprop(string memory propmsg, uint256 _endtime) public {
        if(currprop == 0){propID[currprop].snapId = IGov(tokenaddress).getCurrentSnapshotId();}
        
        uint256 wt = getWeight(currprop);

        uint256 ts = getSupply(propID[currprop].snapId);

        require(wt > (ts/100) , "Need 1% to submit prop");

        currprop++;

        propID[currprop].proposal = propmsg;

        propID[currprop].votesfor += weight[msg.sender].votes;

        propID[currprop].voted[msg.sender] = true;

        propID[currprop].snapId = IGov(tokenaddress).snapshot();

        propID[currprop].createdtime = block.timestamp;

        propID[currprop].endtime = block.timestamp + _endtime;
        
        if(weight[msg.sender].delegators.length > 0){
            removemydelegators();
        }

        emit newproposal(currprop , propmsg);
  
    }

    function init(address tokenaddr, bool selsnap)external{
        require( !inited , "only factory can initialize");
        
        currprop = 0;
        
        selsnap = snap;
        
        tokenaddress = tokenaddr;
        
        inited = true;
        
        emit initialize(tokenaddress);
    }

    function combineWeight(address del)public{
        weight[del].votes += weight[msg.sender].votes;

        weight[del].delegated[msg.sender] += weight[msg.sender].votes;

        weight[del].delegators[weight[msg.sender].delegators.length] = msg.sender;

        weight[msg.sender].votes = 0;
    }
    
    function removemydelegators() internal {
        uint i = 0;
        for(i = 0; i < weight[msg.sender].delegators.length ; i++){

            address del;

            del = weight[msg.sender].delegators[i];

            weight[msg.sender].votes -= weight[msg.sender].delegated[del];

            weight[del].votes = weight[msg.sender].delegated[del];
            
            propID[currprop].voted[del] = true;
            
            weight[msg.sender].delegators[i] = address(0x0);
            
        }
    }


}