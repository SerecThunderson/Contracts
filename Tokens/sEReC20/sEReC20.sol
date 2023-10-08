/filter /sEReC20 // SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract sEReC20 {

    string public name;
    string public symbol;
    uint public decimals;
    uint public totalSupply;

    mapping(address => uint) public balanceOf;
    mapping(address => mapping(address => uint)) public allowance;

    event Transfer(address indexed from, address indexed to, uint value);
    event Approval(address indexed owner, address indexed spender, uint value);

    constructor(string memory name_, string memory symbol_, uint decimals_, uint supply_) {
        name = name_; symbol = symbol_; decimals = decimals_;
        totalSupply = supply_ * 10 ** decimals_;
        balanceOf[msg.sender] = totalSupply;
    }

    function approve(address owner, address spender, uint amount) public virtual returns (bool) {
        allowance[owner][spender] = amount;
        emit Approval(owner, spender, amount);
        return true;
    }

    function transfer(address to, uint amount) public virtual returns (bool) {
        _transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint amount) public virtual returns (bool) {
        _spendAllowance(from, msg.sender, amount);
        _transfer(from, to, amount);
        return true;
    }

    function _transfer(address from, address to, uint amount) internal virtual {
        require(balanceOf[from] >= amount, "ERC20: transfer amount exceeds balance");
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
    }

    function _spendAllowance(address owner, address spender, uint amount) internal virtual {
        require(allowance[owner][spender] >= amount, "ERC20: insufficient allowance");
        approve(owner, spender, allowance[owner][spender] - amount);
    }

}
