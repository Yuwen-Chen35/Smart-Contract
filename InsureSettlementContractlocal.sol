pragma solidity ^0.4.16;

//#######################################Safe Math Library Declaration#####################
library SafeMath {
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        if (a==0) {
            return 0;
        }
        uint c = a * b;
        assert(c / a == b);
        return c;
    }
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a / b;
        return c;
    }
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        assert(b <= a);
        return a - b;
    }
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        assert(c >= a);
        return c;
    }
}

//#######################################Interface Declaration#############################
interface token {
    function transfer(address receiver, uint amount) external;
	function CheckamountLeft(address object) returns(uint256);
	function transferFrom(address sender,address receiver, uint amount);
}

contract Transfer{
//#######################################Variable Declaration##############################
    struct Client{  //Client structure 
        address ClientAddress;  //Client wallet address
        uint Order;  //Client's order in all clients
        uint Amount;  //Client's token amount
        uint InsureType;  //Client's insurance type in uint representation
        uint InsureDuration;  //Client's insurance duration in unit "days"
        uint InsureTimeStart;  //Client's insurance start time
        uint [] TransactionRecord;  //Client's transaction record using the array
        uint [] MarkRecord;  //Client's mark record using the array
    }
    uint ClientNumber;  //Client's number which can be used to find each client
    mapping(uint => Client) ClientMap;  //A map which link the ClientNumber and Client structure
    
    using SafeMath for uint;  //Import Safe Math library
    token public tokenReward;   //Token name
    uint amountRecord;  //Variable to record transaction amount
    uint256 public balance;
    uint [] ClientNumberArray;  //Array to store ClientNumber for each Client
    uint [] RecordInitial;  //Array used to initiate
    uint NumberOfClients = 0;  //Total number of Client
    address Owner;  //The order of this new client in the whole clients

//#######################################Modifier#########################################
    modifier OnlyOwner {  //Modifier that the function can be constructed only when the sender is the owner of the contract
        require (msg.sender == Owner);
        _;
    }

//######################################Construct function################################
    function Transfer() public{  //Contruct function
        tokenReward = token(0xdedb3dadc0b1bcbd48f397dd6c1ba352f6a325a8); //Add token contract address here
        Owner = msg.sender;  //The sender is the owner of the contract
    }

//######################################Main function#####################################
    function NewClient(address _ClientAddress, uint _InsureType, uint _ClientNumber, uint _InsureDuration) {  //Import new client
        require (checkIfExistNumber(_ClientNumber) == false);
        require (checkIfExistAddress(_ClientAddress) == false);
        NumberOfClients++;
        ClientNumber = _ClientNumber;
        ClientMap[ClientNumber] = Client(_ClientAddress, NumberOfClients, 0, _InsureType, _InsureDuration, now, RecordInitial, RecordInitial);
        ClientNumberArray.length = NumberOfClients;
        ClientNumberArray[NumberOfClients - 1] = _ClientNumber;
    }
    
    function DeleteClient(uint _ClientNumber) OnlyOwner {  //Delete the client
        Client storage _Client = ClientMap[_ClientNumber];
        remove(_Client.Order - 1);
        delete ClientMap[_ClientNumber];
    }
    
    function UpdateMark(uint _ClientNumber, uint _Mark) public OnlyOwner{
        Client storage _Client = ClientMap[_ClientNumber];
        _Client.MarkRecord.length++;
        _Client.MarkRecord[_Client.MarkRecord.length - 1] = _Mark;
    }
      
    function WithDrawalToken(uint amount) public payable OnlyOwner {  //Withdrawal the token in the contract to the main pool
        amountRecord=amount;
        tokenReward.transfer(0x5C7EF0BB5eAAb9Cd864114a04d109e40CDBb832B,amount); //Address: The address of the main token pool. Amount: The amount of token that withdrawal
        //The total amount of the token stored in the contract can be checked by the "balanceOf" function in Token contract.
    }
    
    function Settlement(uint _ClientNumber, uint amount) public payable OnlyOwner {  //Transfer the token in the main pool to client
        require (ifExpired(_ClientNumber) == false);
        Client storage _Client = ClientMap[_ClientNumber];
        _Client.Amount = _Client.Amount.add(amount);
        _Client.TransactionRecord.length++;
        _Client.TransactionRecord[_Client.TransactionRecord.length - 1] = amount;
        tokenReward.transferFrom(0x5C7EF0BB5eAAb9Cd864114a04d109e40CDBb832B, _Client.ClientAddress, amount);
    }

//################################################Condition function##############################
    function remove(uint index) OnlyOwner returns (uint[]) {  //To modify the array of the ClientNumber
        if (index >= ClientNumberArray.length) return;

        for (uint i = index; i < ClientNumberArray.length-1; i++){
            ClientNumberArray[i] = ClientNumberArray[i+1];
            ClientMap[ClientNumberArray[i+1]].Order--;
        }
        delete ClientNumberArray[ClientNumberArray.length-1];
        ClientNumberArray.length--;
        return ClientNumberArray;
    }
    
    
    function checkIfExistNumber (uint _ClientNumber) public view returns (bool){  //Check if the new client's number is existed
        for (uint i = 0; i < ClientNumberArray.length; i++){
            if (ClientNumberArray[i] == _ClientNumber) return true;
        }
        return false;
    }
    
    function checkIfExistAddress (address _ClientAddress) public view returns (bool){  //Check if the new client's address is existed in the array
        for (uint i = 0; i < ClientNumberArray.length; i++){
            if (ClientMap[ClientNumberArray[i]].ClientAddress == _ClientAddress) return true;
        }
        return false;
    }
    
//################################################Callback function##############################
    function checkAmountTransfer() public view returns(uint){  //Check the amount of transfer
        return amountRecord;
    }
    
    function CheckInsuranceType(uint _ClientNumber) public view returns (uint){  //Check insurance type
        Client storage _Client = ClientMap[_ClientNumber];
        return _Client.InsureType;
    }
    
    function CheckClientAddress(uint _ClientNumber) public view returns (address){  //Check client wallet address
        Client storage _Client = ClientMap[_ClientNumber];
        return _Client.ClientAddress;
    }
    
    function checkAmount(address target) public view returns (uint256){  //Check amount of the address
        balance = tokenReward.CheckamountLeft(target);
        return balance;
    }
    
    function checkArrayLength() public view returns (uint){  //Check array length
        return ClientNumberArray.length;
    }
    
    function checkOrder (uint _ClientNumber) public view returns (uint) {  //Check client's order
        Client storage _Client = ClientMap[_ClientNumber];
        return _Client.Order;
    }
    
    function ifExpired (uint _ClientNumber) public view returns (bool){  //Check if the contract is expired
        Client storage _Client = ClientMap[_ClientNumber];
        return (now >= (_Client.InsureTimeStart + _Client.InsureDuration * 1 days));
    }
    
    function checkRecord (uint _ClientNumber, uint _Number) public view returns (uint) {  //Check the record of the client
        Client storage _Client = ClientMap[_ClientNumber];
        return _Client.TransactionRecord[_Number - 1];
    }
}
