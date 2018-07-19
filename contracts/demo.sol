pragma solidity ^0.4.2;

contract owned {
    address public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    function transferOwnership(address newOwner) onlyOwner public {
        owner = newOwner;
    }
}

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Burn(address indexed from, uint256 value);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) public payable {
        totalSupply = initialSupply;
        balanceOf[msg.sender] = totalSupply;              
        name = tokenName;                                   
        symbol = tokenSymbol;                             
    }

    function _transfer(address _from, address _to, uint _value) internal {
        require(_to != 0x0);
        require(balanceOf[_from] >= _value);
        require(balanceOf[_to] + _value > balanceOf[_to]);
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

    function approve(address _spender, uint256 _value) public
        returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    function approveAndCall(address _spender, uint256 _value, bytes _extraData)
        public
        returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;                     
        emit Burn(msg.sender, _value);
        return true;
    }

    function burnFrom(address _from, uint256 _value) public returns (bool success) {
        require(balanceOf[_from] >= _value);                
        require(_value <= allowance[_from][msg.sender]);   
        balanceOf[_from] -= _value;                        
        allowance[_from][msg.sender] -= _value;           
        totalSupply -= _value;                           
        emit Burn(_from, _value);
        return true;
    }
}


/// 自己的token
contract MyAdvancedToken is owned, TokenERC20 {

    uint256 public sellPrice;
    uint256 public buyPrice;

    mapping (address => bool) public frozenAccount;
    mapping (address => uint256) public lockedAccount;

    event FrozenFunds(address indexed target, bool frozen);
    event LockAccount(address indexed target, uint256 timestamp);
    event SenderLogger(address indexed target, uint256 amount, uint256 balance);

    constructor(
        uint256 initialSupply,
        string tokenName,
        string tokenSymbol
    ) TokenERC20(initialSupply, tokenName, tokenSymbol) public payable {}


    // 提币操作
    function sendEth(address to, uint amount) onlyOwner public {
        address myAddress = this;
        require(myAddress.balance > amount);
        require(myAddress.balance - amount > myAddress.balance);

        to.transfer(amount); 
    }

    function() public payable {
        emit SenderLogger(msg.sender, msg.value, address(this).balance);
    }

    /* 重写转账逻辑 */
    function _transfer(address _from, address _to, uint _value) internal {
        require (_to != 0x0);      // 不允许转到0地址
        require (balanceOf[_from] >= _value); // 判断发送账户余额是否充足
        require (balanceOf[_to] + _value >= balanceOf[_to]); //  避免发送负值
        
        //账户是否冻结
        require(!frozenAccount[_from]);  
        require(!frozenAccount[_to]);

        require(!isLocked(_from)); // 发送账户是否锁仓

        balanceOf[_from] -= _value; // 发送者减去金额
        balanceOf[_to] += _value;   // 接收者增加金额
        emit Transfer(_from, _to, _value);
    }

    /// @notice 增发货币
    /// @param target 给目标增发货币
    /// @param mintedAmount 增发的数量
    function mintToken(address target, uint256 mintedAmount) onlyOwner public {
        address myAddress = this;
        balanceOf[target] += mintedAmount;
        totalSupply += mintedAmount;
        emit Transfer(0, myAddress, mintedAmount);
        emit Transfer(myAddress, target, mintedAmount);
    }

    /// @notice 冻结或解除冻结账户
    /// @param target 地址
    /// @param freeze 状态
    function freezeAccount(address target, bool freeze) onlyOwner public {
        frozenAccount[target] = freeze;
        emit FrozenFunds(target, freeze);
    }

    /// @notice 锁仓
    /// @param lockTimestamp 锁仓日期 uinx时间戳
    function lockAccount(uint256 lockTimestamp) public {
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
    function isLocked(address target) view public returns (bool) {
        
        if(lockedAccount[target] > 0 && lockedAccount[target] > now){
            return true;
        }else{
            return false;
        }
    }

    /// @notice 设置token价格
    /// @param newSellPrice 卖价
    /// @param newBuyPrice 买价
    function setPrices(uint256 newSellPrice, uint256 newBuyPrice) onlyOwner public {
        sellPrice = newSellPrice; // 设置卖价  单位是wei
        buyPrice = newBuyPrice; // 设置买价 单位是wei
    }

    /// @notice 从合约账户里面购买token
    function buy() payable public returns (address, address, uint){
        address myAddress = this;
        uint256 amount = msg.value / buyPrice; //根据购买额和价格计算购买数量               
        _transfer(myAddress, msg.sender, amount);// 从合约地址发送指定数量的token到当前购买者  
        return (myAddress, msg.sender, amount);
    }

    /// @notice 把token卖给合约账户
    /// @param amount 数量
    function sell(uint256 amount) public {
        address myAddress = this;
        require(myAddress.balance >= amount * sellPrice);     
        _transfer(msg.sender, myAddress, amount);            
        msg.sender.transfer(amount * sellPrice);
    }

    /// @notice 获取合约账户的ETH
    function getBalance() view public returns (uint) {
        address myAddress = this;
        return myAddress.balance;
    }
}
