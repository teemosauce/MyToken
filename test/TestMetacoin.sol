pragma solidity ^0.4.2;

import "truffle/Assert.sol";
import "truffle/DeployedAddresses.sol";
import "../contracts/MyToken.sol";

contract TestMetacoin {

    function testInitialBalanceUsingDeployedContract() public {
        MyToken meta = MyToken(DeployedAddresses.MyToken());

        uint expected = 10000;

        Assert.equal(token.getBalance(tx.origin), expected, "Owner should have 10000 MyToken initially");
    }

    function testInitialBalanceWithNewMyToken() public {
        MyToken meta = new MyToken();

        uint expected = 10000;

        Assert.equal(token.getBalance(tx.origin), expected, "Owner should have 10000 MyToken initially");
    }

}
