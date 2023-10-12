// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../sEReC20.sol";

interface IUniswapV2Router02 {
    function WETH() external pure returns (address);
}

interface IUniswapV2Factory {
    function getPair(address tokenA, address tokenB) external view returns (address pair);
}

interface IUniswapV2Pair {
    function sync() external;
}

contract Rebasable is sEReC20 {

    address public dev;
    mapping(address => bool) public isSetter;
    uint public base = 1000000; // initial rebase rate
    IUniswapV2Pair public uniswapPair;
    IUniswapV2Router02 public uniswapV2Router;

    event Rebase(uint newRebaseRate);
    event SetterUpdated(address setter, bool status);

    modifier onlyDev() {
        require(msg.sender == dev, "Not the dev");
        _;
    }

    modifier onlySetter() {
        require(isSetter[msg.sender], "Not a setter");
        _;
    }

    constructor(
        string memory name_, 
        string memory symbol_, 
        uint decimals_, 
        uint supply_, 
        address uniswapFactoryAddress, 
        address uniswapRouterAddress
    ) 
        sEReC20(name_, symbol_, decimals_, supply_) {
        dev = msg.sender;
        IUniswapV2Factory uniswapFactory = IUniswapV2Factory(uniswapFactoryAddress);
        uniswapV2Router = IUniswapV2Router02(uniswapRouterAddress);
        address pair = uniswapFactory.getPair(address(this), uniswapV2Router.WETH());
        uniswapPair = IUniswapV2Pair(pair);
    }

    function setRebaseRate(uint newRate) public onlySetter {
        base = newRate;
        uniswapPair.sync();
        emit Rebase(newRate);
    }

    function updateSetter(address setter, bool status) public onlyDev {
        isSetter[setter] = status;
        emit SetterUpdated(setter, status);
    }

    function balanceOf(address account) public view override returns (uint) {
        return super.balanceOf(account) * base / 1000000;
    }

    function totalSupply() public view override returns (uint) {
        return super.totalSupply() * base / 1000000;
    }

    function _transfer(address from, address to, uint amount) internal override {
        uint adjustedAmount = amount * 1000000 / base;
        super._transfer(from, to, adjustedAmount);
    }
}
