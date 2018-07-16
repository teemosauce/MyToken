pragma solidity ^0.4.2;

interface tokenRecipient { function receiveApproval(address _from, uint256 _value, address _token, bytes _extraData) external; }

contract TokenERC20 {
    string public name;
    string public symbol;
    uint8 public decimals = 18;
    uint256 public totalSupply;

    // This creates an array with all balances
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed from, address indexed to, uint256 value);
    
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    event Burn(address indexed from, uint256 value);

    constructor (uint256 initialSupply, string tokenName, string tokenSymbol) public {
        totalSupply = initialSupply * 10 ** uint256(decimals);  // Update total supply with the decimal amount
        balanceOf[msg.sender] = totalSupply;                // 合约创建者分配所有token 这里可以制定分配规则

        name = tokenName;                                  
        symbol = tokenSymbol;                             
    }

    function _transfer(address _from, address _to, uint _value) internal {
        // 禁止转向0x0地址 使用burn燃烧代币
        require(_to != 0x0);
        //判断账户余额是否大于转账金额
        require(balanceOf[_from] >= _value);
        //防止转的是负数
        require(balanceOf[_to] + _value > balanceOf[_to]);
        //缓存一下转账钱两个地址的总金额
        uint previousBalances = balanceOf[_from] + balanceOf[_to];
        //转账地址减金额
        balanceOf[_from] -= _value;
        //接收地址加金额
        balanceOf[_to] += _value;
        emit Transfer(_from, _to, _value);
        //判断转账后的总金额是否等于转帐前的总金额
        assert(balanceOf[_from] + balanceOf[_to] == previousBalances);
    }

	//从执行合约地址账户转账
    function transfer(address _to, uint256 _value) public returns (bool success) {
        _transfer(msg.sender, _to, _value);
        return true;
    }

	//从指定地址账户转账
    function transferFrom(address _from, address _to, uint256 _value) public returns (bool success) {
        require(_value <= allowance[_from][msg.sender]);     // Check allowance
        allowance[_from][msg.sender] -= _value;
        _transfer(_from, _to, _value);
        return true;
    }

	// 限制指定地址的可转金额
    function approve(address _spender, uint256 _value) public returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // Set allowance for other address and notify
    function approveAndCall(address _spender, uint256 _value, bytes _extraData) public returns (bool success) {
        tokenRecipient spender = tokenRecipient(_spender);
        if (approve(_spender, _value)) {
            spender.receiveApproval(msg.sender, _value, this, _extraData);
            return true;
        }
    }

    // 燃烧token 从总量中擦除
    function burn(uint256 _value) public returns (bool success) {
        require(balanceOf[msg.sender] >= _value);   
        balanceOf[msg.sender] -= _value;            
        totalSupply -= _value;               
        emit Burn(msg.sender, _value);
        return true;
    }

	// 燃烧某个地址的token
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