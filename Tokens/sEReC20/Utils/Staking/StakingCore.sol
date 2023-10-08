// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../sEReC20.sol";

contract StakingCore is sEReC20("Staked Ethereum", "sETH", 18, 0) {

    uint256 public totalStaked;

    function stake() public payable {
        require(msg.value > 0, "Cannot stake 0 ETH");
        uint256 stakingTokens = (totalStaked == 0) ? msg.value : (msg.value * totalSupply()) / totalStaked;
        totalStaked += msg.value;
        _mint(msg.sender, stakingTokens);
    }

    function unstake(uint256 amount) public {
        require(amount > 0 && amount <= balanceOf(msg.sender), "Invalid unstake amount");
        uint256 ethAmount = (amount * totalStaked) / totalSupply();
        require(ethAmount > 0, "Not enough ETH to unstake");
        _burn(msg.sender, amount);
        totalStaked -= ethAmount;
        payable(msg.sender).transfer(ethAmount);
    }

}
