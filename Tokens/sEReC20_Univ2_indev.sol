pragma solidity 0.8.18;

interface IUniswapV2Router02{
    function WETH() external pure returns (address);
    function factory() external pure returns (address);
    function swapExactTokensForETHSupportingFeeOnTransferTokens(uint amountIn, uint amountOutMin, address[] calldata path, address to, uint deadline) external;
    function addLiquidityETH(address token, uint amountTokenDesired, uint amountTokenMin, uint amountETHMin, address to, uint deadline) external payable returns (uint amountToken, uint amountETH, uint liquidity);
}

interface IUniswapV2Factory{
    function createPair(address tokenA, address tokenB) external returns (address pair);
}

contract sEReC20_UniV2 {
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    address private _v2Router;
    address private _WETH;
    address public _v2Pair;
    address public _dev;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    modifier onlyDev() {
        require(msg.sender == _dev, "Only the developer can call this function");
        _;
    }

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint supply_, address v2Router_, uint amountTokenDesired) payable {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _balances[msg.sender] = supply_ * 10 ** decimals_;
        _totalSupply = supply_ * 10 ** decimals_;
        _v2Router = v2Router_;
        _WETH = IUniswapV2Router02(_v2Router).WETH();
        _v2Pair = IUniswapV2Factory(IUniswapV2Router02(_v2Router).factory()).createPair(address(this), _WETH);
        _addLiquidity(amountTokenDesired, 0, msg.value);
        _dev = msg.sender;
    }

    function name() public view returns (string memory) {return _name;}
    function symbol() public view returns (string memory) {return _symbol;}
    function decimals() public view returns (uint8) {return _decimals;}
    function totalSupply() public view returns (uint256) {return _totalSupply;}
    function balanceOf(address account) public view returns (uint256) {return _balances[account];}
    function allowance(address owner, address spender) public view returns (uint256) {return _allowances[owner][spender];}

    function transfer(address to, uint256 amount) public returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function approve(address spender, uint256 amount) public returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) public returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint256 amount) internal {
        require(_balances[from] >= amount, "ERC20: transfer amount exceeds balance");
        _balances[from] -= amount;
        _balances[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _approve(address owner, address spender, uint256 amount) internal {
        _allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function _spendAllowance(address owner, address spender, uint256 amount) internal {
        uint256 currentAllowance = allowance(owner, spender);
        require(currentAllowance >= amount, "ERC20: insufficient allowance");
        _approve(owner, spender, currentAllowance - amount);
    }

    function _setDev (address dev_) external onlyDev {
        _dev = dev_;
    }

    function _addLiquidity(uint amountTokenDesired, uint amountTokenMin, uint amountETHMin) public payable onlyDev {
        _transfer(msg.sender, address(this), amountTokenDesired);
        _approve(address(this), _v2Router, amountTokenDesired);
        IUniswapV2Router02(_v2Router).addLiquidityETH{value: msg.value}(address(this), amountTokenDesired, amountTokenMin, amountETHMin, msg.sender, block.timestamp);
    }
}

//add buy and sell taxes
//whitelists where appropriate
//buy limits if they want
//blacklist functions
//add eth withdraw, token withdraw
