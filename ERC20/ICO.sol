//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

import "./ERC-20.sol";

contract MyICO is OlivasToken {
    address public admin;
    address payable public deposit;
    uint256 public hardCap = 300 ether;
    uint256 public raisedAmout;
    uint256 public tokenPrice = 0.0000001 ether;

    uint256 public saleStart = block.timestamp;
    uint256 public saleEnd = block.timestamp + 604800;
    uint256 public tokenTradeStart = saleEnd + 3600;

    uint256 public maxInvestment = 1 ether;
    uint256 public minInvestment = 0.0001 ether;

    enum State {
        beforeStart,
        running,
        halted,
        afterEnd
    }
    State public icoState;

    event Invest(address invertor, uint256 value, uint256 tokens);

    constructor(address payable _deposit) {
        deposit = _deposit;
        admin = msg.sender;
        icoState = State.beforeStart;
    }

    modifier OnlyAdmin() {
        require(admin == msg.sender);
        _;
    }

    function halt() public OnlyAdmin {
        icoState = State.halted;
    }

    function resume() public OnlyAdmin {
        icoState = State.running;
    }

    function changeDeposit(address payable _deposit) public OnlyAdmin {
        deposit = _deposit;
    }

    function getCurrentState() public view returns (State) {
        if (icoState == State.halted) {
            return State.halted;
        } else if (block.timestamp < saleStart) {
            return State.beforeStart;
        } else if (block.timestamp >= saleStart && block.timestamp <= saleEnd) {
            return State.running;
        } else {
            return State.afterEnd;
        }
    }

    function invest() public payable returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.running);
        require(minInvestment <= msg.value && maxInvestment >= msg.value);

        raisedAmout += msg.value;
        require(raisedAmout <= hardCap);

        uint256 tokens = msg.value / tokenPrice;

        balances[msg.sender] += tokens;
        balances[founder] -= tokens;
        deposit.transfer(msg.value);

        emit Invest(msg.sender, msg.value, tokens);

        return true;
    }

    receive() external payable {
        invest();
    }

    function burn() public returns (bool) {
        icoState = getCurrentState();
        require(icoState == State.afterEnd);
        balances[founder] = 0;
        return true;
    }

    function transfer(address to, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(block.timestamp > tokenTradeStart);

        super.transfer(to, tokens);
        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public override returns (bool success) {
        require(block.timestamp > tokenTradeStart);

        super.transferFrom(from, to, tokens);
        return true;
    }
}
