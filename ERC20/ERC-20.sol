//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0 <0.9.0;

// ----------------------------------------------------------------------------
// EIP-20: ERC-20 Token Standard
// https://eips.ethereum.org/EIPS/eip-20
// -----------------------------------------

interface ERC20Interface {
    function totalSupply() external view returns (uint256);

    function balanceOf(address tokenOwner)
        external
        view
        returns (uint256 balance);

    function transfer(address to, uint256 tokens)
        external
        returns (bool success);

    function allowance(address tokenOwner, address spender)
        external
        view
        returns (uint256 remaining);

    function approve(address spender, uint256 tokens)
        external
        returns (bool success);

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) external returns (bool success);

    event Transfer(address indexed from, address indexed to, uint256 tokens);
    event Approval(
        address indexed tokenOwner,
        address indexed spender,
        uint256 tokens
    );
}

contract OlivasToken is ERC20Interface {
    string public name = "OlivasToken";
    string public symbol = "DPEPDPE";
    uint256 public decimals = 18;
    uint256 public override totalSupply;

    address public founder;
    mapping(address => uint256) public balances;

    mapping(address => mapping(address => uint256)) allowed;

    constructor() {
        founder = msg.sender;
        totalSupply = 1000000000;
        balances[founder] = totalSupply;
    }

    function balanceOf(address tokenOwner)
        public
        view
        override
        returns (uint256 balance)
    {
        return balances[tokenOwner];
    }

    function transfer(address to, uint256 tokens)
        public
        virtual
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);

        balances[msg.sender] -= tokens;
        balances[to] += tokens;
        emit Transfer(msg.sender, to, tokens);

        return true;
    }

    function allowance(address tokenOwner, address spender)
        public
        view
        override
        returns (uint256 remaining)
    {
        return allowed[tokenOwner][spender];
    }

    function approve(address spender, uint256 tokens)
        public
        override
        returns (bool success)
    {
        require(balances[msg.sender] >= tokens);

        allowed[msg.sender][spender] = tokens;
        emit Approval(msg.sender, spender, tokens);

        return true;
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokens
    ) public virtual override returns (bool success) {
        require(allowed[from][to] >= tokens);
        require(balances[from] >= tokens);

        allowed[from][to] -= tokens;
        balances[from] -= tokens;
        balances[to] += tokens;

        return true;
    }
}
