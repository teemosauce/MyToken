pragma solidity ^0.4.18;

import "./TokenERC20.sol";
import "./Owned.sol";

contract MyToken is Owned, TokenERC20 {
    
    uint256 public sellPrice;
    uint256 public buyPrice;

    event LockAccount(address target, uint timestamp);

    mapping(address => uint) public locks;

    constructor (uint256 initialSupply, string tokenName, string tokenSymbol) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    function lockAccount(address target, uint lockSeconds) public {

        //判断锁日期是否大于当前时间
        require(now < lockSeconds);

        //判断是否已经锁仓 并且锁仓时间大于所传时间
        require(locks[target] > lockSeconds);

        // 修改锁仓时间
        locks[target] = lockSeconds;

        emit LockAccount(target, lockSeconds);
    }

    // 判断是否锁仓
    function isLocked(address target) public returns (bool success) {
        return locks[target] > now;
    }

    function _transfer(address _from,  address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value >= balanceOf[_to]);

        //没有锁仓才能继续往下走
        require(!isLocked(_from));

        balanceOf[_from] -= _value;                   
        balanceOf[_to] += _value;                       
        emit Transfer(_from, _to, _value);
    }

    // 新发行资产
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, this, mintedAmount);
        emit Transfer(this, target, mintedAmount);
    }

    //资产对eth价格
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice;
        buyPrice = newBuyPrice;
    }

    function buy() payable public {
        uint amount = msg.value / buyPrice;
        _transfer(this, msg.sender, amount);
    }

    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);
        _transfer(msg.sender, this, amount);         
        msg.sender.transfer(amount * sellPrice);
    }

}