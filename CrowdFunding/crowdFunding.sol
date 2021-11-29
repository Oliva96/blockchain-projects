//SPDX-License-Identifier: GPL-3.0
 
pragma solidity >=0.6.0 <0.9.0;

contract CrowdFunding {
    mapping (address => uint) public contributors;
    address public admin;
    uint public numberOfContributors;
    uint public minimumContribution;
    uint public raisedAmount;
    uint public goalMoney;
    uint public deadline;

    struct Request {
        string description;
        address payable recipient;
        uint numOfVoters;
        uint value;
        bool completed;
        mapping (address => bool) voters;
    }

    //this mapping is like a dynamic array because dynamic array can not contains mappings, 
    //and Request has a mapping (voters).
    mapping (uint => Request) public requests;
    uint public numOfRequests = 0;

    // events to emit
    event ContributeEvent(address _sender, uint _value);
    event CreateRequestEvent(string _description, address _recipient, uint _value);
    event MakePaymentEvent(address _recipient, uint _value);

    constructor(uint _goalMoney, uint _deadline, uint _minimumContribution) {
        admin = msg.sender;
        minimumContribution = _minimumContribution;
        goalMoney = _goalMoney;
        deadline = block.timestamp + _deadline;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "Only the admin can execute this");
        _;
    }

    function getBalance() public view returns(uint) {
        return address(this).balance;
    }

    function contribute() public payable {
        require(msg.value >= minimumContribution, "You have not sent the minimum contribution");
        require(block.timestamp < deadline, "The Deadline has passed!");

        if(contributors[msg.sender] == 0) {
            numberOfContributors++;
        }
        contributors[msg.sender] += msg.value;
        raisedAmount += msg.value;

        emit ContributeEvent(msg.sender, msg.value);
    }

    // a contributor can get a refund if goal was not reached within the deadline
    function getRefund() public {
        require(block.timestamp > deadline, "Deadline has not passed");
        require(raisedAmount < goalMoney, "The goal has not been reached");
        require(contributors[msg.sender] > 0, "Sorry, you are not a contributor");

        payable (msg.sender).transfer(contributors[msg.sender]);
        contributors[msg.sender] = 0;
        numberOfContributors--;
    }

    function createRequest(string memory _description, address payable _recipient, uint _value) public onlyAdmin {
        Request storage newRequest = requests[numOfRequests];
        numOfRequests++;

        newRequest.description = _description;
        newRequest.recipient = _recipient;
        newRequest.value = _value;
        newRequest.completed = false;
        newRequest.numOfVoters = 0;
        
        emit CreateRequestEvent(_description, _recipient, _value);
    }

    function voteRequest(uint _numRequest) public {
        Request storage thisRequest = requests[_numRequest];
        require(thisRequest.completed == false, "This request has been completed");
        require(contributors[msg.sender] > 0, "You must be a contributor");
        require(thisRequest.voters[msg.sender] == false, "You have already voted");

        thisRequest.voters[msg.sender] = true;
        thisRequest.numOfVoters++;
    }

    function makePayment(uint _numRequest) public onlyAdmin{
        Request storage thisRequest = requests[_numRequest];
        require(thisRequest.completed == false, "This request has been completed");
        require(thisRequest.numOfVoters > numberOfContributors / 2, "The request needs more than 50% of the contributors");
        
        thisRequest.recipient.transfer(thisRequest.value);
        thisRequest.completed = true;

        emit MakePaymentEvent(thisRequest.recipient, thisRequest.value);
    }

}