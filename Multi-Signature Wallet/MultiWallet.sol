// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

/*
This is a simple multi-signature wallet that only uses ETH.
*/

import "./WalletUsers.sol";

contract MultiWallet is WalletUsers {

  //Wallet address:
  address Wallet = address(this);
  
  constructor(string memory _LeadName) public {
    admin memory NewLead = admin(Admins.length, _LeadName, msg.sender);
    Admins.push(NewLead);
  }

  //Withdrawal request struct:
  struct txnRequest {
    uint txID;
    address payable toAddress;
    address fromAddress;
    uint amount;
    string approvalStatus;
}

  //Approval status enum:
  enum APPROVE { SUBMITTED, PENDING, APPROVED, FAILED }

  //Maps txID to APPROVE enum:
  mapping(uint => APPROVE) ApprovalStatus;

  //Wallet balance:
  mapping(address => uint) public walletBalance;

  //ID to index mapping:
  mapping(uint => uint) txnIDToIndex;

  //ID counter:
  uint txIDCounter = 0;

  //History of all withdrawal requests:
  txnRequest[] public requestHistory;

  //Events:
  event transactionSubmitted(uint txID, uint adminID, string ApprovalStatus);
  event transactionDetails(address sender, address receiver, uint amount);
  event adminApproval(uint txID, uint adminID);
  event transactionApproved(uint txID);
  event transactionSuccess(uint txID);
  event transactionFailure(uint txID);
  event transactionCancelled(uint txID, uint adminID);

  //Requires Admin has not already approved:
  modifier AdminHasNOTApproved (uint txID) {
    require(AdminApproved[msg.sender][txID] == false, "Already approved");
    _;
  }

  //Transaction request submission:
  //Add additional functionality for ERC20 tokens;
  //Add functionality for transfers between users;
  function submitTransaction(address payable _recipient, uint _amount) external returns (bool success) {
    require (getBalance() >= _amount, "Error: Insufficient balance");

    uint txID = txIDCounter;
    address _sender = msg.sender;
    ApprovalStatus[txID] = APPROVE.SUBMITTED;
    txnIDToIndex[txID] = getRequestHistoryLength();
    string memory approvalStatus = "Submitted";

    emit transactionSubmitted(txID, addressToID[_msgSender()], "Submitted");
    emit transactionDetails(_msgSender(), _recipient, _amount);


    txnRequest memory pendingRequest =
    txnRequest(
              txID,
              _recipient,
              _sender,
              _amount,
              approvalStatus);

    requestHistory.push(pendingRequest);
    txIDCounter++;
    success = true;
  }

  //Confirms transfer requests awaiting confirmation:
  function confirmTransfer(uint _txID) external AdminHasNOTApproved(_txID) {
    uint txIDIndex = txnIDToIndex[_txID];
    require (ApprovalStatus[_txID] != APPROVE.APPROVED, "Transaction already approved");
    
    if (ApprovalStatus[_txID] == APPROVE.SUBMITTED || ApprovalStatus[_txID] == APPROVE.FAILED) {
    ApprovalStatus[_txID] = APPROVE.PENDING;
    requestHistory[txIDIndex].approvalStatus = "Pending";
    }
    
    txnRequest memory approvedTxn = requestHistory[txIDIndex];
    AdminApproved[msg.sender][_txID] = true;
    
    emit adminApproval(_txID, addressToID[msg.sender]);
    
    _approval(approvedTxn.txID, approvedTxn.toAddress, approvedTxn.amount);

  }

  //This function tallies up Admin approvals for a transaction before running a withdraw function on it:
  function _approval(uint _txID, address payable _toAddress, uint _amount) private {
    uint txIDIndex = txnIDToIndex[_txID];
    uint numApproved = 0;
    for (uint n = 0; n < Admins.length; n++) {

      AdminApproved[Admins[n].adminAddress][_txID] == true ?
        numApproved++ :
        numApproved;
    }

    if (numApproved == adminsRequired) {
      ApprovalStatus[_txID] = APPROVE.APPROVED;
      requestHistory[txIDIndex].approvalStatus = "Approved";

      emit transactionApproved(_txID);
      emit transactionDetails(requestHistory[txIDIndex].fromAddress, requestHistory[txIDIndex].toAddress, requestHistory[txIDIndex].amount);

      _withdraw(_toAddress, _amount, _txID);
    }
  }

//VARIANT 1: PERFORMS _cancelPending WHEN TXN FAILS
  //Withdraws to private wallet;
/*
  function _withdraw(address payable _toAddress, uint _amount, uint _txID) private returns (bool success) {
      uint txIDIndex = txnIDToIndex[_txID];
      if (getBalance() < _amount) {
        emit transactionFailure(_txID);
        _cancelPending(txIDIndex);
        success = false;
      }
      else if (getBalance() >= _amount) {

        uint initialBalance = getBalance();
        walletBalance[Wallet] -= _amount;

        _toAddress.transfer(_amount);

        assert(initialBalance > getBalance());
        emit transactionSuccess(_txID);
        return success = true;
      }
  }
*/

//VARIANT 2: APPROVALS RESET TO 0 WHEN TXN FAILS, approvalStatus SET TO "Failed"
//--Admins must re-approve withdrawal;
  function _withdraw(address payable _toAddress, uint _amount, uint _txID) private returns (bool success) {
      uint txIDIndex = txnIDToIndex[_txID];
      if (getBalance() < _amount) {
        emit transactionFailure(_txID);
        for (uint i = 0; i < Admins.length; i++) {
          if (AdminApproved[Admins[i].adminAddress][_txID] == true) {
            (AdminApproved[Admins[i].adminAddress][_txID] = false);
          }
        }
        requestHistory[txIDIndex].approvalStatus = "Failed";
        ApprovalStatus[_txID] = APPROVE.SUBMITTED;
        success = false;
      }
      else if (getBalance() >= _amount) {

        uint initialBalance = getBalance();
        walletBalance[Wallet] -= _amount;

        _toAddress.transfer(_amount);

        assert(initialBalance > getBalance());
        emit transactionSuccess(_txID);
        return success = true;
      }
  }


//Cancels transaction, permissioned for sender of txn and for contract owner;
  function cancelTransaction(uint _txID) external {
    uint txIDIndex = txnIDToIndex[_txID];
    require (requestHistory[txIDIndex].fromAddress == _msgSender() || _msgSender() == owner(),
      "Only sender or contract owner may cancel");
    _cancelPending(txIDIndex);
    emit transactionCancelled(_txID, addressToID[_msgSender()]);
  }

//Clears all failed transactions from history;
  function clearFailed() external {
    for (uint i = 0; i < getRequestHistoryLength(); i++) {
      if (ApprovalStatus[i] == APPROVE.FAILED) {
        _cancelPending(i);
      }
    }
  }

  //Cancels pending transaction, internal, uses index value:
  function _cancelPending(uint _txIDIndex) internal {
    if (getRequestHistoryLength() > 0) {
      txnRequest memory newTxn = requestHistory[getRequestHistoryLength() - 1];
      requestHistory[_txIDIndex] = newTxn;
      txnIDToIndex[newTxn.txID] = _txIDIndex;
    }
    requestHistory.pop();
  }

  //This deposits ether into the smart contract:
  function depositETH() external payable {
    require(msg.value > 0, "Error: Cannot deposit 0");
    walletBalance[Wallet] += msg.value;
  }

  //This shows the current balance of the Wallet:
  function getBalance() public view returns (uint) {
      return walletBalance[Wallet];
  }

  //Returns number of pending transactions:
  function getPending() public view returns (uint) {
    uint _numberPending = 0;
    for (uint n = 0; n < getRequestHistoryLength(); n++) {

        if (ApprovalStatus[requestHistory[n].txID] == APPROVE.PENDING ||
          ApprovalStatus[requestHistory[n].txID] == APPROVE.SUBMITTED) {
            _numberPending ++;
        }
        if (ApprovalStatus[requestHistory[n].txID] == APPROVE.APPROVED) {
            continue;
        }
    }
    return _numberPending;
  }


  function getRequestHistory() public view returns(txnRequest[] memory) {
    return requestHistory;
  }

  function getRequestHistoryLength() public view returns(uint length) {
    return requestHistory.length;
  }

 //Destroyes contract and transfers all amounts to CEO;
    function Close() public onlyOwner() {
        selfdestruct(payable(msg.sender));
    }


}
