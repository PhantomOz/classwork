// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

contract BuggySafe {
    uint256 balance;
    address owner;

    constructor() {
        owner = msg.sender;
    }

    function deposit() public payable {
        require(owner == msg.sender, "Only Owner can Deposit");
        balance += msg.value;
    }

    function withdraw() public {
        require(owner == msg.sender, "Only Owner can Withdraw");
        require(
            balance < address(this).balance,
            "Not enough funds to withdraw"
        );

        (bool success, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(success, "Transfer failed");
    }

    function getBalance() public view returns (uint256) {
        return balance;
    }

    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
}
