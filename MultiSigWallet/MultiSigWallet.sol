// SPDX-License-Identifier: UNLICENSED
// My try of SmartContractProgrammer's MultiSigWallet

pragma solidity ^0.8.13;

contract MultiSigWallet {

    address[] public owners;
    uint public numConfirmationsRequired;
    mapping(address => bool) isOwner;

    struct Transaction {
        address to;
        uint value;
        bool executed;
        uint numConfirmations;
    }
    Transaction[] public transactions;
    mapping(uint => mapping(address => bool)) public isConfirmed;

    constructor (address[] memory _owners, uint _numConfirmationsRequired) {
        require(_owners.length > 0, "owners required");
        require(_numConfirmationsRequired > 0 && _numConfirmationsRequired <= _owners.length, "invalid number of required confirmations");

        for (uint i = 0; i < _owners.length; i++) {
            address owner = _owners[i];

            require(owner != address(0), "invalid owner");
            require(!isOwner[owner], "you have already confirmed");

            owners.push(owner);
            isOwner[owner] = true;
        }

        numConfirmationsRequired = _numConfirmationsRequired;
    }

    modifier onlyOwner() {
        require(isOwner[msg.sender], "not owner");
        _;
    }

    modifier txExists(uint _txIndex) {
        require(_txIndex < transactions.length, "tx does not exist");
        _;
    }

    modifier notExecuted(uint _txIndex) {
        require(transactions[_txIndex].executed == false, "transaction already executed");
        _;
    }

    modifier notConfirmed(uint _txIndex) {
        require(!isConfirmed[_txIndex][msg.sender], "you have already confirmed this transaction");
        _;
    }

    modifier Confirmed(uint _txIndex) {
        require(isConfirmed[_txIndex][msg.sender], "you have not confirmed this transaction");
        _;
    }

    function submitTransaction(address _to, uint _value) public onlyOwner {
        
        transactions.push(Transaction({
            to: _to,
            value: _value,
            executed: false,
            numConfirmations: 0
        }));
    }
    
    function confirmTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) notConfirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        isConfirmed[_txIndex][msg.sender] = true;

        transaction.numConfirmations += 1;
    }

    function revokeConfirmation(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) Confirmed(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        
        isConfirmed[_txIndex][msg.sender] = false;
        transaction.numConfirmations -= 1;
    }

    function executeTransaction(uint _txIndex) public onlyOwner txExists(_txIndex) notExecuted(_txIndex) {
        Transaction storage transaction = transactions[_txIndex];
        
        require(transaction.numConfirmations >= numConfirmationsRequired, "Need more Confirmations");
        transaction.executed = true;
    }

    receive() payable external {}
}