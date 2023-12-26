// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

contract Dao {
    struct Proposal {
        uint256 id;
        string description;
        uint256 amount;
        address payable receipient;
        uint256 votes;
        uint256 end;
        bool isExecuted;
    }

    mapping(address => bool) private isInvestor;
    mapping(address => uint256) public numOfShares;
    mapping(address => mapping(uint256 => bool)) public isVoted;
    mapping(address => mapping(address => bool)) public withdrawlStatus;
    address[] public investorsList;

    mapping(uint256 => Proposal) public proposals;

    uint256 public totalShares;
    uint256 public availableFunds;
    uint256 public contributionTimeEnd;
    uint256 public nextProposalId;
    uint256 public voteTime;
    uint256 public quorum;
    address public manager;

    constructor(
        uint256 _contributionTimeEnd,
        uint256 _voteTime,
        uint256 _quorum
    ) {
        require(_quorum > 0 && _quorum < 100, "Not Valid Values");
        contributionTimeEnd = block.timestamp + _contributionTimeEnd;
        voteTime = _voteTime;
        _quorum = quorum;
        manager = msg.sender;
    }

    modifier onlyInvestor() {
        require(isInvestor[msg.sender] == true, "You are not an investor");
        _;
    }
    modifier onlyManager() {
        require(manager == msg.sender, "You are not an manager");
        _;
    }

    function contribution() public payable {
        require(contributionTimeEnd >= block.timestamp,"Contribution time ended");
        require(msg.value>0,"Send more than 0 ether");
        isInvestor[msg.sender]=true;
        numOfShares[msg.sender]=numOfShares[msg.sender]+msg.value;
        totalShares+=msg.value;
        availableFunds+=msg.value;
        investorsList.push(msg.sender);
    }
    function redeemShare(uint amount)public onlyInvestor{
        require(numOfShares[msg.sender]>=amount,"You dont have enough shares");
        require(availableFunds>=amount,"Not enough funds");
        numOfShares[msg.sender]-=amount;
        if(numOfShares[msg.sender]==0){
            isInvestor[msg.sender]=false;
        }
        availableFunds-=amount;
        payable(msg.sender).transfer(amount);
    }
    function transferShare(uint amount,address to)public onlyInvestor(){
        require(availableFunds>=amount,"Not enough funds");
        require(numOfShares[msg.sender]>=amount,"you dont have enough shares");
        numOfShares[msg.sender]-=amount;
        if(numOfShares[msg.sender]==0){
            isInvestor[msg.sender]=false;
        }
        numOfShares[to]+=amount;
        isInvestor[to]=true;
        investorsList.push(to);

    }
    function createProposal(string calldata description,uint amount,address payable receipient)public onlyManager{
        require(availableFunds>=amount,"Not enough funds");
        proposals[nextProposalId]=Proposal(nextProposalId,description,amount,receipient,0,block.timestamp+voteTime,false);
        nextProposalId++;
    }
    function voteProposal(uint proposalId)public onlyInvestor(){
        Proposal storage proposal=proposals[proposalId];
        require(isVoted[msg.sender][proposalId]==false,"You have already voted for this proposal ");
        require(proposal.end>=block.timestamp,"Voting time ended");
        require(proposal.isExecuted==false,"It is already executed");
        isVoted[msg.sender][proposalId]=true;
        proposal.votes+=numOfShares[msg.sender];

    }
    function executeProposal(uint proposalId)public onlyManager(){
        Proposal storage proposal=proposals[proposalId];
        require(((proposal.votes*100)/totalShares)>=quorum,"Majority does not support");
        proposal.isExecuted=true;
        _transfer(proposal.amount,proposal.receipient);
    }
    function _transfer(uint amount,address payable receipient)private{
        receipient.transfer(amount);
    }
    function ProposalList() public view returns(Proposal[] memory){
        Proposal[] memory arr= new Proposal[](nextProposalId-1);
        for(uint i=1;i<nextProposalId;i++){
            arr[i]=proposals[i];
        }
        return arr;
    }
}
 