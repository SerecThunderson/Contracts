// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./StakingCore.sol";

contract AdminStakingControls is StakingCore {

    address public admin;
    mapping(address => bool) public isDealer;

    modifier onlyAdmin() {
        require(msg.sender == admin, "Not admin");
        _;
    }

    modifier onlyDealer() {
        require(isDealer[msg.sender] || msg.sender == admin, "Not permissioned");
        _;
    }

    constructor() {admin = msg.sender;}

    function dealerWithdraw(uint256 amount, address receiver) public onlyDealer {
        require(amount <= totalStaked, "Not enough ETH in contract");
        totalStaked -= amount;
        payable(receiver).transfer(amount);
    }

    function dealerDeposit() public payable onlyDealer {
        totalStaked += msg.value;
    }

    function setPermissioned(address user, bool status) public onlyAdmin {
        isDealer[user] = status;
    }

    function transferAdmin(address newAdmin) public onlyAdmin {
        admin = newAdmin;
    }

}
