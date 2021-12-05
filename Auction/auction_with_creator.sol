//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

// this contract will deploy the Auction contract
contract AuctionCreator {
    // declaring a dynamic array with addresses of deployed contracts
    Auction[] public auctions;

    // declaring the function that will deploy contract Auction
    function createAuction(uint256 _blocksDuration, uint256 _highestBid)
        public
    {
        // passing msg.sender to the constructor of Auction
        Auction newAuction = new Auction(
            payable(msg.sender),
            _blocksDuration,
            _highestBid
        );
        auctions.push(newAuction); // adding the address of the instance to the dynamic array
    }
}

contract Auction {
    address payable public owner;
    uint256 highestBid;
    uint256 public startBlock;
    uint256 public endBlock;
    string public ipfsHash;

    enum State {
        Started,
        Running,
        Ended,
        Canceled
    }
    State public auctionState;

    address payable public highestBidder;
    mapping(address => uint256) public bids;
    uint256 bidIncrement;

    //the owner can finalize the auction and get the highestBid only once
    bool public ownerFinalized = false;

    constructor(
        address payable _eoa,
        uint256 _blocksDuration,
        uint256 _highestBid
    ) {
        owner = _eoa;
        auctionState = State.Running;

        startBlock = block.number;
        endBlock = startBlock + _blocksDuration;
        highestBid = _highestBid;

        ipfsHash = "";
        bidIncrement = 1000000000000000000;
    }

    // declaring function modifiers
    modifier notOwner() {
        require(msg.sender != owner);
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    modifier afterStart() {
        require(block.number >= startBlock);
        _;
    }

    modifier beforeEnd() {
        require(block.number <= endBlock);
        _;
    }

    //a helper pure function (it neither reads, nor it writes to the blockchain)
    function min(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a <= b) {
            return a;
        } else {
            return b;
        }
    }

    // only the owner can cancel the Auction
    function cancelAuction() public onlyOwner {
        auctionState = State.Canceled;
    }

    // only the owner can ended the Auction
    function endedAuction() public onlyOwner {
        auctionState = State.Ended;
    }

    // the main function called to place a bid
    function placeBid() public payable notOwner afterStart beforeEnd {
        // to place a bid auction should be running
        require(auctionState == State.Running);
        // minimum value allowed to be sent
        require(msg.value > 0.0001 ether);

        require(msg.value >= highestBid + bidIncrement);

        // updating the mapping variable
        bids[msg.sender] = msg.value;

        highestBidder = payable(msg.sender);
    }

    function finalizeAuction() public {
        // the auction has been Canceled or Ended
        require(auctionState == State.Canceled || block.number > endBlock);

        // only the owner or a bidder can get their money back
        require(msg.sender == owner || bids[msg.sender] > 0);

        // the recipient will get the value
        address payable recipient;
        uint256 value;

        if (auctionState == State.Canceled && msg.sender != owner) {
            // auction canceled, not ended
            recipient = payable(msg.sender);
            value = bids[msg.sender];
        } else {
            // auction ended, not canceled
            if (auctionState == State.Ended) {
                if (msg.sender == owner && ownerFinalized == false) {
                    //the owner finalizes the auction
                    recipient = owner;
                    value = highestBid;
                    //the owner can finalize the auction and get the highestBid only once
                    ownerFinalized = true;
                } else {
                    if (msg.sender != highestBidder) {
                        //this is neither the owner nor the highest bidder (it's a regular bidder)
                        recipient = payable(msg.sender);
                        value = bids[msg.sender];
                    }
                }
            }
        }
        // resetting the bids of the recipient to avoid multiple transfers to the same recipient
        bids[recipient] = 0;

        //sends value to the recipient
        recipient.transfer(value);
    }
}
