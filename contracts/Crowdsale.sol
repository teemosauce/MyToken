pragma solidity ^0.4.21;

import "./SafeMath.sol";

interface Token {
    function transfer(address receiver, uint amount) external;
}

contract Crowdsale {
    
    address public beneficiary; //众筹eth成功的收款方
    uint256 public fundingGoal; //众筹额度
    uint256 public hasFunding = 0; //已众筹额
    uint256 public deadline; //众筹期限

    uint256 public price; //以太币兑token汇率
    
    Token public token; 

    bool public fundingGoalReached = false; //是否达到众筹目标
    bool public closed = false; //众筹是否关闭

    mapping (address => uint256) public balanceOf;

    event FundTransfer(address target, uint256 amount, bool isContribution);
    event GoalReached(address beneficiary, uint256 totalAmount);

    constructor(address _beneficiary, uint256 _ethAmount, uint256 _deadline, uint256 _price, address whichToken) public {
        beneficiary = _beneficiary;
        fundingGoal = _ethAmount * 1 ether;
        deadline = _deadline;
        price = _price * 1 ether;
        token = Token(whichToken);
    }

    function () public payable {
        require(!closed);

        uint256 amount = msg.value;

        balanceOf[msg.sender] = SafeMath.add(balanceOf[msg.sender], amount);
        hasFunding = SafeMath.add(hasFunding, amount);

        token.transfer(msg.sender, SafeMath.div(amount, price));

        emit FundTransfer(msg.sender, amount, true);
    }

    modifier afterDeadline(){
        if(now >= deadline) _;
    }

    function checkGoalReached() public afterDeadline {
        if(hasFunding >= fundingGoal){
            fundingGoalReached = true;
            emit GoalReached(beneficiary, hasFunding);
        }
        closed = true;
    }

    function safeWithdrawal() afterDeadline public {
        if(!fundingGoalReached){
            uint256 amount = balanceOf[msg.sender];

            balanceOf[msg.sender] = 0;

            if(amount > 0){
                msg.sender.transfer(amount);
                emit FundTransfer(msg.sender, amount, false);
            }
        }


        if(fundingGoalReached && beneficiary == msg.sender){
            beneficiary.transfer(amount);
            emit FundTransfer(beneficiary, hasFunding, false);
        }
    }
}


