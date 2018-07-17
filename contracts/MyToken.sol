pragma solidity ^0.4.2;

import "./TokenERC20.sol";
import "./Owned.sol";

contract MyToken is Owned, TokenERC20 {
    
    uint256 public sellPrice;
    uint256 public buyPrice;

    event LockAccount(address target, uint256 timestamp);
    event ForzenAccount(address target, bool frozen);

    address public lastLockAdderss;
    uint256 public lastLockTimestamp;

    mapping(address => uint256) public lockedAccount;
    mapping (address => bool) public frozenAccount;

    constructor (uint256 initialSupply, string tokenName, string tokenSymbol) TokenERC20(initialSupply, tokenName, tokenSymbol) public {}

    function lockAccount(address target, uint256 lockTimestamp) public {

        //判断锁日期是否大于当前时间
        uint256 timestamp = block.timestamp;

        require(timestamp < lockTimestamp);
        
        //判断是否已经锁仓 并且锁仓时间大于所传时间
        require(lockedAccount[target] > lockTimestamp);

        // 修改锁仓时间
        lockedAccount[target] = lockTimestamp;

        lastLockAdderss = target;
        lastLockTimestamp = lockTimestamp;

        emit LockAccount(target, lockTimestamp);
    }

    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit ForzenAccount(target, freeze);
    }

    function _transfer(address _from,  address _to, uint256 _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require (balanceOf[_to] + _value >= balanceOf[_to]);
        
        // 账户没有被冻结
        require(!frozenAccount[_from]);
        require(!frozenAccount[_to]);  

        //发送账户没有锁仓
        require(lockedAccount[_from] < block.timestamp);

        balanceOf[_from] -= _value;                   
        balanceOf[_to] += _value;                       
        emit Transfer(_from, _to, _value);
    }

    // 代币增发
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

    //设置买卖价格
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