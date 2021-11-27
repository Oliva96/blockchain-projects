//SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.5.0 <0.9.0;

contract Lottery{
    address payable[] players;
    address public manager;

    constructor() {
        manager = msg.sender;
    }

    receive() external payable {
        require(msg.value == 0.1 ether);
        players.push(payable(msg.sender));
    }

    function getBalance() public view returns(uint) {
        require(msg.sender == manager);
        return address(this).balance;
    }

    function random() public pure returns(uint) {
        return uint(keccak256(abi.encodePacked(block.difficulty, block.timestamp, players.lenght)));
    }

    function pickWinner() public {
        require(msg.sender == manager);
        require(players.lenght >= 3);

        uint r = random();
        uint index = r % players.lenght;
        address payable winner;
        winner = players[index];
        winner.transfer(getBalance());
        players = new address payable[](0);
    }

}