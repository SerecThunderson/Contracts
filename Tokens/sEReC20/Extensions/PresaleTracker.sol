// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../../sEReC20.sol";

contract PresaleTracker is sEReC20 {

    uint public _ethCap;
    uint public _maxBuy;
    uint public _minBuy;
    bool public _public;
    address private _dv;

    mapping(address => bool) public _whitelisted;

    modifier onlyDev() {
        require(msg.sender == _dv, "Only the developer can call this function"); _;
    }

    constructor(string memory name_, string memory symbol_, uint ethCap_, uint minBuy_, uint maxBuy_)
        sEReC20(name_, symbol_, 18, 0) {
            _ethCap = ethCap_;
            _minBuy = minBuy_;
            _maxBuy = maxBuy_;
            _dv =  msg.sender;
        }

    function openToPublic(bool public_) public onlyDev {_public = public_;}
    function withdraw(address to_) public onlyDev {payable(to_).transfer(address(this).balance);}
    function changeDev (address dev_) public onlyDev {_dv = dev_;}

    receive() external payable {buyTokens();}

    function buyTokens() public payable {
        require(msg.value >= _minBuy, "You must purchase more than min amount!");
        require(_balanceOf[msg.sender] + msg.value <= _maxBuy || _public, "You must purchase less than max amount!");
        require(_totalSupply + msg.value <= _ethCap, "Purchase would exceed total supply");
        require(_public || _whitelisted[msg.sender], "You are not whitelisted for the private sale!");
        _balanceOf[msg.sender] += msg.value; _totalSupply += msg.value;
        emit Transfer(address(0), msg.sender, msg.value);
    }

    function updateWhitelist(address[] memory addresses, bool whitelisted_) public onlyDev {
        for (uint i = 0; i < addresses.length; i++) {
            _whitelisted[addresses[i]] = whitelisted_;
        }
    }

    function setLimits (uint ethCap_, uint maxBuy_) public onlyDev {
        _ethCap = ethCap_;
        _maxBuy = maxBuy_;
    }

}
