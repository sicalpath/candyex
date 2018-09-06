pragma solidity ^0.4.4;


contract ERC20 {
    function totalSupply() constant returns (uint totalSupply);
    function balanceOf(address _owner) constant returns (uint balance);
    function transfer(address _to, uint _value) returns (bool success);
    function transferFrom(address _from, address _to, uint _value) returns (bool success);
    function approve(address _spender, uint _value) returns (bool success);
    function allowance(address _owner, address _spender) constant returns (uint remaining);
    event Transfer(address indexed _from, address indexed _to, uint _value);
    event Approval(address indexed _owner, address indexed _spender, uint _value);
}

contract Owned {
    address public owner;
    event OwnershipTransferred(address indexed _from, address indexed _to);

    function Owned() {
        owner = msg.sender;
    }

    modifier onlyOwner {
        if (msg.sender != owner) throw;
        _;
    }

    function transferOwnership(address newOwner) onlyOwner {
        OwnershipTransferred(owner, newOwner);
        owner = newOwner;
    }
}




contract CandyReceipt is Owned {

	event NewReceipt(uint receiptId, address asset, uint endTime);

	address public asset = 0xbf2179859fc6d5bee9bf9158632dc51678a4100e;
	address public bonusAsset = 0xbf2179859fc6d5bee9bf9158632dc51678a4100e;
	uint public saveTime = 86400; //1 days;
	uint public interestRate = 10; // rate of asset to bonus per day/hour/minute



	struct Receipt {

		address asset;		//token to deposit  ELF:0xbf2179859fc6d5bee9bf9158632dc51678a4100e
	    address owner;		//owner of this receipt
	    address bonusAsset;
	    uint amount;
	    uint interestRate;
	    uint startTime;      
	    uint endTime;
	    bool finished; 

  	}


  	Receipt[] public receipts;

  	mapping (uint => address) public receiptToOwner;


  	//检查某token是否授权了足够的额度
  	modifier haveAllowance(address _asset, uint _amount) {

  		uint allowance = ERC20(asset).allowance(msg.sender, address(this));
	    require(allowance >= _amount);
	    _;
	}

	//检查存单是否到期
	modifier exceedEndtime(uint _id) {

	    require(receipts[_id].endTime <= now);
	    _;
	}

	//检查存单是否已经完成
	modifier notFinished(uint _id) {

	    require(receipts[_id].finished == false);
	    _;
	}


  	function _createReceipt(
  		address _asset, 
  		address _owner, 
  		address _bonusAsset, 
  		uint _amount, 
  		uint _interestRate, 
  		uint _startTime, 
  		uint _endTime,
  		bool _finished
  		) internal {

	    uint id = receipts.push(Receipt(_asset, _owner, _bonusAsset, _amount, _interestRate, _startTime, _endTime, _finished)) - 1;

	    receiptToOwner[id] = msg.sender;
	    NewReceipt(id, _asset, _endTime);
	}


	//create new receipt
	function createReceipt(uint _amount) external haveAllowance(asset,_amount) {
  
		//other processes

		//deposit token to this contract
		if (!ERC20(asset).transferFrom(msg.sender, address(this), _amount)) throw;

		//
	    _createReceipt(asset, msg.sender, bonusAsset, _amount, interestRate, now, now + saveTime, false );
  	}

  	//finish the receipt and withdraw bonus and token
  	function finishReceipt(uint _id) external notFinished(_id) exceedEndtime(_id) {
  
		//other processes

		//withdraw bonus and token
		//maybe more security check!!!!
		//保证要有足够的allowance
		uint bonusAmount = receipts[_id].amount * receipts[_id].interestRate / 100;	//percent rate of asset to bonus    1000elf->100 other token

		if (!ERC20(bonusAsset).transfer(receipts[_id].owner, bonusAmount )) throw;

		if (!ERC20(asset).transfer(receipts[_id].owner, receipts[_id].amount )) throw;

		//完成
	    receipts[_id].finished = true;
  	}


  	function fixSaveTime(uint _period) external onlyOwner {
  		saveTime = _period;
  	}



}


contract CandyHelper is CandyReceipt {

	//some helper funtions


}



