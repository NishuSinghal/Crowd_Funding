// SPDX-License-Identifier: GPL-3.0

pragma solidity >= 0.5.0 < 0.9.0;

contract funding{
    mapping(address=>uint) public contributers; 
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributers;

    struct Request{
        string description; 
        address payable recipient;
        uint value;
        bool completed; 
        uint noOfVoters;
        mapping(address=>bool) voters;
      
    }
    mapping(uint=>Request) public request; 
    uint public numRequest;

    constructor(uint _setTarget,uint setDeadline){
        target=_setTarget;
        deadline=block.timestamp+setDeadline;
        minimumContribution=100 wei;
        manager=msg.sender;
    }
    function sendEth() public payable{
        require(block.timestamp<deadline,"Deadline has passed.");
        require(msg.value>=minimumContribution,"Minimum contribution is mot met.");
        if(contributers[msg.sender]==0){
             noOfContributers++;
        }
        contributers[msg.sender]+=msg.value;
        raisedAmount+=msg.value;
    }
    function getContractBalance() view public returns(uint){
        return address(this).balance;
    }
    function refund() public{
        require(block.timestamp>deadline && raisedAmount<target);
        require(contributers[msg.sender]>0);
        address payable user=payable(msg.sender);
        user.transfer(contributers[msg.sender]);
        contributers[msg.sender]=0;
    }
    modifier onlyManager(){
        require(msg.sender==manager,"Only manager can call this function.");
        _;
    }
    function createRequests(string memory _description,address payable _recipient,uint _value) onlyManager public{
        Request storage newRequest=request[numRequest];
        numRequest++;
        newRequest.description=_description;
        newRequest.recipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;
    }
    function voteRequest(uint _requestNo) public{
        require(contributers[msg.sender]>0,"You must have to be a contributor to vote");
        Request storage thisRequest=request[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You already gave vote.");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }
    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest=request[_requestNo];
        require(thisRequest.completed==false,"The request has  been completed.");
        require(thisRequest.noOfVoters>noOfContributers/2,"Majority does no support");
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}