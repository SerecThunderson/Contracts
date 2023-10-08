// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "../sEReC20.sol";

interface IUniswapV2Router02{
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external payable returns (uint amountToken, uint amountETH, uint liquidity
    );
}

interface IUniswapV2Factory{function createPair(address tokenA, address tokenB) external returns (address pair);}

contract sEReC20_UniV2 is sEReC20 {

    IUniswapV2Router02 public uniswapV2Router;

    uint public _buyTax = 0;
    uint public _sellTax = 0;
    uint public _max = 1;
    uint public _transferDelay = 1;
    uint public _swapAmount = 1000 * 10**18;

    address private _dev;
    address[] public _path;
    address private _v2Pair;
    address private _collector;
    address private _v2Router = 0x7a250d5630B4cF539739dF2C5dAcb4c659F2488D;

    mapping(address => bool) public blacklisted;
    mapping(address => bool) public whitelisted;
    mapping(address => uint) private _lastTransferBlock;

    modifier onlyDev() {
        require(msg.sender == _dev, "Only the developer can call this function");
        _;
    }

    constructor(address collector_, string memory name_, string memory symbol_, uint decimals_, uint supply_) 
        sEReC20(name_, symbol_, decimals_, supply_) {
            _collector = collector_; _dev = msg.sender;
            _balanceOf[address(this)] = _totalSupply;
            emit Transfer(address(0), address(this), _totalSupply);
            uniswapV2Router = IUniswapV2Router02(_v2Router);
            _v2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
            _path = new address[](2);
            _path[0] = address(this);
            _path[1] = uniswapV2Router.WETH();
            whitelisted[address(this)] = true;
            whitelisted[msg.sender] = true;
    }

    function maxInt() internal view returns (uint) {return (_totalSupply * _max) / 100;}

    function _transfer(address from, address to, uint amount)internal override{

        require(_balanceOf[from] >= amount && (amount + _balanceOf[to] <= maxInt() ||
            whitelisted[from] || whitelisted[to] || to == _v2Pair),
            "ERC20: transfer amount exceeds balance or max wallet"
        );

        require(!blacklisted[from] && !blacklisted[to], "ERC20: YOU DON'T HAVE THE RIGHT");

        require(block.number >= _lastTransferBlock[from] + _transferDelay ||
            from == _v2Pair || whitelisted[from] || whitelisted[to],
            "ERC20: transfer delay not met"
        );

        uint taxAmount = 0;
        if ((from == _v2Pair || to == _v2Pair) && !whitelisted[from] && !whitelisted[to]) {
            if (to == _v2Pair) {taxAmount = (amount * _sellTax) / 100;} 
            else {taxAmount = (amount * _buyTax) / 100;}

            _balanceOf[address(this)] += taxAmount;
            emit Transfer(from, address(this), taxAmount);

            _lastTransferBlock[from] = block.number; _lastTransferBlock[to] = block.number;
            if (_balanceOf[address(this)] > _swapAmount && to == _v2Pair) {
                _swapBack(_balanceOf[address(this)]);
            }
        }

        super._transfer(from, to, amount - taxAmount);
    }

    function updateWhitelist(address[] memory addresses, bool whitelisted_) external onlyDev {
        for (uint i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = whitelisted_;
        }
    }

    function updateBlacklist(address[] memory addresses, bool blacklisted_) external{
        require(msg.sender == _dev, "Only the developer can call this function");
        for (uint i = 0; i < addresses.length; i++) {blacklisted[addresses[i]] = blacklisted_;}
    }

    function _swapBack(uint amount_) internal{
        approve(address(this), _v2Router, amount_ + 100);
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount_, 0, _path, _collector, block.timestamp);
    }

    function _addLiquidity() external onlyDev{
        approve(address(this), _v2Router, _balanceOf[address(this)]); _buyTax = 15; _sellTax = 15;
        uniswapV2Router.addLiquidityETH{value: address(this).balance}(address(this), _balanceOf[address(this)], 0, 0, msg.sender, block.timestamp);
    }

    function withdraw(uint amount_) external onlyDev {
        payable(_dev).transfer(address(this).balance);
        _transfer(address(this), _dev, amount_);
    }

    function deposit() external payable onlyDev{}
}
