pragma solidity ^0.4.11;

contract ERC20 {
     function totalSupply() public constant returns (uint256 totalSupply);
     function balanceOf(address _owner) public constant returns (uint256 balance);
     function transfer(address _to, uint256 _value) public returns (bool success);
     function transferFrom(address _from, address _to, uint256 _value) public returns (bool success);
     function approve(address _spender, uint256 _value) public returns (bool success);
     function allowance(address _owner, address _spender) public constant returns (uint256 remaining);
     event Transfer(address indexed _from, address indexed _to, uint256 _value);
     event Approval(address indexed _owner, address indexed _spender, uint256 _value);
 }
 
 /*
    Utilities & Common Modifiers
*/
contract SafeMath {
    /**
        constructor
    */
    function SafeMath() public {
    }

    // validates an address - currently only checks that it isn't null
    modifier validAddress(address _address) {
        require(_address != 0x0);
        _;
    }

    // verifies that the address is different than this contract address
    modifier notThis(address _address) {
        require(_address != address(this));
        _;
    }

    // Overflow protected math functions

    /**
        @dev returns the sum of _x and _y, asserts if the calculation overflows

        @param _x   value 1
        @param _y   value 2

        @return sum
    */
    function safeAdd(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x + _y;
        assert(z >= _x);
        return z;
    }

    /**
        @dev returns the difference of _x minus _y, asserts if the subtraction results in a negative number

        @param _x   minuend
        @param _y   subtrahend

        @return difference
    */
    function safeSub(uint256 _x, uint256 _y) pure internal returns (uint256) {
        assert(_x >= _y);
        return _x - _y;
    }

    /**
        @dev returns the product of multiplying _x by _y, asserts if the calculation overflows

        @param _x   factor 1
        @param _y   factor 2

        @return product
    */
    function safeMul(uint256 _x, uint256 _y) pure internal returns (uint256) {
        uint256 z = _x * _y;
        assert(_x == 0 || z / _x == _y);
        return z;
    }
}

/**
    ERC20 Standard Token implementation
*/
contract ERC20Token is ERC20, SafeMath {
    string public standard = "Token 0.1";
    string public name = "";
    string public symbol = "";
    uint8 public decimals = 0;
    uint256 public totalSupply = 0;
    mapping (address => uint256) public balanceOf;
    mapping (address => mapping (address => uint256)) public allowance;

    event Transfer(address indexed _from, address indexed _to, uint256 _value);
    event Approval(address indexed _owner, address indexed _spender, uint256 _value);

    /**
        @dev constructor

        @param _name        token name
        @param _symbol      token symbol
        @param _decimals    decimal points, for display purposes
    */
    function ERC20Token(string _name, string _symbol, uint8 _decimals) public {
        require(bytes(_name).length > 0 && bytes(_symbol).length > 0); // validate input

        name = _name;
        symbol = _symbol;
        decimals = _decimals;
    }

    /**
        @dev send coins
        throws on any error rather then return a false flag to minimize user errors

        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transfer(address _to, uint256 _value)
        public
        validAddress(_to)
        returns (bool success)
    {
        balanceOf[msg.sender] = safeSub(balanceOf[msg.sender], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(msg.sender, _to, _value);
        return true;
    }

    /**
        @dev an account/contract attempts to get the coins
        throws on any error rather then return a false flag to minimize user errors

        @param _from    source address
        @param _to      target address
        @param _value   transfer amount

        @return true if the transfer was successful, false if it wasn't
    */
    function transferFrom(address _from, address _to, uint256 _value)
        public
        validAddress(_from)
        validAddress(_to)
        returns (bool success)
    {
        allowance[_from][msg.sender] = safeSub(allowance[_from][msg.sender], _value);
        balanceOf[_from] = safeSub(balanceOf[_from], _value);
        balanceOf[_to] = safeAdd(balanceOf[_to], _value);
        Transfer(_from, _to, _value);
        return true;
    }

    /**
        @dev allow another account/contract to spend some tokens on your behalf
        throws on any error rather then return a false flag to minimize user errors

        to minimize the risk of the approve/transferFrom attack vector
        approve has to be called twice
        in 2 separate transactions - once to change the allowance to 0 and secondly to change it to the new allowance value

        @param _spender approved address
        @param _value   allowance amount

        @return true if the approval was successful, false if it wasn't
    */
    function approve(address _spender, uint256 _value)
        public
        validAddress(_spender)
        returns (bool success)
    {
        // if the allowance isn't 0, it can only be updated to 0 to prevent an allowance change immediately after withdrawal
        require(_value == 0 || allowance[msg.sender][_spender] == 0);

        allowance[msg.sender][_spender] = _value;
        Approval(msg.sender, _spender, _value);
        return true;
    }
}


contract Owned {
    address public owner;
    address public newOwner;

    event OwnerUpdate(address _prevOwner, address _newOwner);

    /**
        @dev constructor
    */
    function Owned() public {
        owner = msg.sender;
    }

    // allows execution by the owner only
    modifier ownerOnly {
        assert(msg.sender == owner);
        _;
    }

    /**
        @dev allows transferring the contract ownership
        the new owner still needs to accept the transfer
        can only be called by the contract owner

        @param _newOwner    new contract owner
    */
    function transferOwnership(address _newOwner) public ownerOnly {
        require(_newOwner != owner);
        newOwner = _newOwner;
    }

    /**
        @dev used by a new owner to accept an ownership transfer
    */
    function acceptOwnership() public {
        require(msg.sender == newOwner);
        OwnerUpdate(owner, newOwner);
        owner = newOwner;
        newOwner = 0x0;
    }
}


contract KTCToken is ERC20Token {
    
    uint256 constant public KTC_UNIT = 10 ** 18;
    uint256 public totalSupply = 1 * (10**9) * KTC_UNIT;
    
    //  Constants 
    uint256 constant public maxPresaleSupply = 600 * 10**6 * KTC_UNIT;           // Total presale supply at max bonus
    uint256 constant public minCrowdsaleAllocation = 200 * 10**6 * KTC_UNIT;     // Min amount for crowdsale
    uint256 constant public incentivisationAllocation = 100 * 10**6 * KTC_UNIT;  // Incentivisation Allocation
    uint256 constant public ktcTeamAllocation = 74 * 10**6 * KTC_UNIT;           // KTC Team allocation

    address public crowdFundAddress;                                             
    address public incentivisationFundAddress;                                   // Address that holds the incentivization funds
    address public ktcTeamAddress;                                               // KTC Team address

    //  Variables

    uint256 public totalAllocatedToTeam = 0;                                     // Counter to keep track of team token allocation
    uint256 public totalAllocated = 0;                                           // Counter to keep track of overall token allocation
    uint256 constant public endTime = 0; // TBD etc 1509494340;                  // 10/31/2017 @ 11:59pm (UTC) crowdsale end time (in seconds)

    bool internal isReleasedToPublic = false;                         // Flag to allow transfer/transferFrom before the end of the crowdfund

    
    /**
        @dev constructor
        @param _crowdFundAddress   Crowdfund address
        @param _ktcTeamAddress     KTC Team address
    */
    function KTCToken(address _crowdFundAddress, address _incentivisationFundAddress, address _ktcTeamAddress)
    ERC20Token("Kick The Coin", "KTC", 18) public
     {
        crowdFundAddress = _crowdFundAddress;
        ktcTeamAddress = _ktcTeamAddress;
        incentivisationFundAddress = _incentivisationFundAddress;
        balanceOf[_crowdFundAddress] = minCrowdsaleAllocation + maxPresaleSupply; // Total presale + crowdfund tokens
        balanceOf[_incentivisationFundAddress] = incentivisationAllocation;       // 10% Allocated for Marketing and Incentivisation
        totalAllocated += incentivisationAllocation;                              // Add to total Allocated funds
    }

}
