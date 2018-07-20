pragma solidity ^0.4.21;

import "./TokenERC20.sol";
import "./Owned.sol";
import "./SafeMath.sol";

/// 自己的token
contract MyToken is Owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;
    bool public stopped = false;

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public lockedAccount;

    event FrozenFunds(address indexed target, bool frozen);
    event LockAccount(address indexed target, uint256 timestamp);
    // event SenderLogger(address indexed target, uint256 amount, uint256 balance);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol,
        uint8 tokenDecimals
    ) TokenERC20(initialSupply, tokenName, tokenSymbol, tokenDecimals) public payable {}

    modifier isRunning(){
        require(!stopped);
        _;
    }

    // function() public payable {
    //     emit SenderLogger(msg.sender, msg.value, address(this).balance);
    // }

    /* 重写转账逻辑 */
    function _transfer(address _from, address _to, uint _value) internal isRunning {
        require (_to != 0x0);      // 不允许转到0地址

        //账户是否冻结
        require(!frozenAccount[_from]);  
        require(!frozenAccount[_to]);

        //账户是否锁仓
        require(!_isLocked(_from)); 
        require(!_isLocked(_to));

        balanceOf[_from] = SafeMath.sub(balanceOf[_from], _value); // 发送者减去金额
        balanceOf[_to] = SafeMath.add(balanceOf[_to], _value);   // 接收者增加金额
        emit Transfer(_from, _to, _value);
    }

    /// @notice 增发货币
    /// @param target 给目标增发货币
    /// @param mintedAmount 增发的数量
    function mintToken(address target, uint256 mintedAmount) public onlyOwner isRunning {
        address self = this;
        balanceOf[target] = SafeMath.add(balanceOf[target], mintedAmount);
        totalSupply = SafeMath.add(totalSupply, mintedAmount);
        emit Transfer(0x0, self, mintedAmount);
        emit Transfer(self, target, mintedAmount);
    }

    /// @notice 冻结或解除冻结账户
    /// @param target 地址
    /// @param freeze 状态
    function freezeAccount(address target, bool freeze) public onlyOwner isRunning {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice 锁仓
    /// @param lockTimestamp 锁仓日期 uinx时间戳
    function lockAccount(uint256 lockTimestamp) public isRunning {
        //判断锁日期是否大于当前时间
        uint256 locktimes = lockTimestamp * 1 seconds;

        require(now < locktimes);
        
        //判断是否锁过仓 并且锁仓时间大于所传时间
        if(lockedAccount[msg.sender] > 0){
            require(lockedAccount[msg.sender] < locktimes);
        }
        
        // 修改锁仓时间
        lockedAccount[msg.sender] = locktimes;

        emit LockAccount(msg.sender, locktimes);
    }

    /// @notice 判断指定地址是否锁仓
    /// @param target 地址
    function _isLocked(address target) view internal returns (bool) {
        if(lockedAccount[target] > 0 && lockedAccount[target] > now)
            return true;
        return false;
    }

    function isLocked() view public returns (bool) {
        return _isLocked(msg.sender);
    }

    /// @notice 设置token价格
    /// @param newSellPrice 卖价
    /// @param newBuyPrice 买价
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice; // 设置卖价  单位是wei
        buyPrice = newBuyPrice; // 设置买价 单位是wei
    }

    /// @notice 从合约账户里面购买token
    function buy() payable public isRunning returns (address, address, uint){
        address myAddress = this;
        uint256 amount = SafeMath.div(msg.value, buyPrice); // 根据购买额和价格计算购买数量               
        _transfer(myAddress, msg.sender, amount);// 从合约地址发送指定数量的token到当前购买者  
        return (myAddress, msg.sender, amount);
    }

    /// @notice 把token卖给合约账户
    /// @param amount 数量
    function sell(uint256 amount) public isRunning {
        address self = this;
        uint256 eth = SafeMath.mul(amount, sellPrice);
        require(self.balance >= eth);     
        _transfer(msg.sender, self, amount);            
        msg.sender.transfer(eth);
    }

    // 提币操作
    function withdrawEther(uint256 amount) onlyOwner public {
        owner.transfer(amount);
    }

    function setName(string tokenName) onlyOwner public{
        name = tokenName;
    }

    function stop() onlyOwner public {
        stopped = true;
    }

    function start() onlyOwner public {
        stopped = false;
    }
}