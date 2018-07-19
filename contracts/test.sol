pragma solidity ^0.4.2;

contract Test {

    string public str;
    uint public index;

    constructor() public{}

    function addStr(string  _str) public {
        str = _concatStr(str, _str);
    }

    function _concatStr(string _a, string _b) private pure returns (string) {
        bytes memory a = bytes(_a);
        bytes memory b = bytes(_b);
        
        string memory ret = new string(a.length + b.length);

        bytes memory retBytes = bytes(ret);

        uint k = 0;
        for (uint i = 0; i < a.length; i++){
            retBytes[k++] = a[i];
        }

        for (i = 0; i < b.length; i++){
            retBytes[k++] = b[i];
        }

        return string(ret);
    }

    function each() public{
        for(uint256 i = 0; i < 100000000; i++){
            index += i;
        }
    }
}