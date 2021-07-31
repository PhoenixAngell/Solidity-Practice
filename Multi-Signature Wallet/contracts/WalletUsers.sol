// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;
pragma abicoder v2;

import "./OpenZeppelinDependencies/Ownable.sol";
import "./OpenZeppelinDependencies/SafeMath.sol";

contract WalletUsers is Ownable {
  using SafeMath for uint256;

  //Address and ID mappings:
  mapping(uint => address) public IDToAddress;
  mapping(address => uint) public addressToID;

  //Maps Admin address and txID for approval:
  mapping(address => mapping(uint => bool)) AdminApproved;
  bool hasApproved;

  //Defines a User struct:
  struct admin {
    uint adminID;
    string adminName;
    address adminAddress;
   }

    //List of all Users in the contract:
    admin[] public Admins;

  //Number of signatures required--requires 2/3 of all Admins;
  uint adminsRequired = Admins.length * 2 / 3;

  function addAdmin (string memory _adminName, address payable _address) external onlyOwner() {
    admin memory NewAdmin = admin(Admins.length, _adminName, _address);
    IDToAddress[NewAdmin.adminID] = _address;
    addressToID[_address] = NewAdmin.adminID;
    Admins.push(NewAdmin);
  }

  function removeAdmin(uint _adminID) public onlyOwner() {
    require(Admins[_adminID].adminAddress != _msgSender(), "Cannot remove owner");
    admin memory NewAdmin = Admins[Admins.length - 1];
    NewAdmin.adminID = _adminID;
    Admins[_adminID] = NewAdmin;
    Admins.pop();
  }

}
