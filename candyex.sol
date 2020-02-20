pragma solidity ^0.4.18;


contract ERC20 {
  uint256 public totalSupply;
  function balanceOf(address who) public view returns (uint256);
  function transfer(address to, uint256 value) public returns (bool);
  function allowance(address owner, address spender) public view returns (uint256);
  function transferFrom(address from, address to, uint256 value) public returns (bool);
  function approve(address spender, uint256 value) public returns (bool);
  event Transfer(address indexed from, address indexed to, uint256 value);
  event Approval(address indexed owner, address indexed spender, uint256 value);
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
    
    using SafeMath for uint256;
    event NewReceipt(uint256 receiptId, address asset, uint256 endTime);

    address public asset = 0xbf2179859fc6d5bee9bf9158632dc51678a4100e;
    address public bonusAsset = 0xbf2179859fc6d5bee9bf9158632dc51678a4100e;
    uint256 public saveTime = 86400; //1 days;
    uint256 public interestRate = 10; // rate of asset to bonus per day/hour/minute



    struct Receipt {

        address asset;      //token to deposit  ELF:0xbf2179859fc6d5bee9bf9158632dc51678a4100e
        address owner;      //owner of this receipt
        address bonusAsset;
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;      
        uint256 endTime;
        bool finished; 

    }


    Receipt[] public receipts;

    mapping (uint256 => address) public receiptToOwner;


    //检查某token是否授权了足够的额度
    modifier haveAllowance(address _asset, uint256 _amount) {

        uint256 allowance = ERC20(asset).allowance(msg.sender, address(this));
        require(allowance >= _amount);
        _;
    }

    //检查存单是否到期
    modifier exceedEndtime(uint256 _id) {

        require(receipts[_id].endTime <= now);
        _;
    }

    //检查存单是否已经完成
    modifier notFinished(uint256 _id) {

        require(receipts[_id].finished == false);
        _;
    }


    function _createReceipt(
        address _asset, 
        address _owner, 
        address _bonusAsset, 
        uint256 _amount, 
        uint256 _interestRate, 
        uint256 _startTime, 
        uint256 _endTime,
        bool _finished
        ) internal {

        uint256 id = receipts.push(Receipt(_asset, _owner, _bonusAsset, _amount, _interestRate, _startTime, _endTime, _finished)) - 1;

        receiptToOwner[id] = msg.sender;
        NewReceipt(id, _asset, _endTime);
    }


    //create new receipt
    function createReceipt(uint256 _amount) external haveAllowance(asset,_amount) {
  
        //other processes

        //deposit token to this contract
        if (!ERC20(asset).transferFrom(msg.sender, address(this), _amount)) throw;

        //
        _createReceipt(asset, msg.sender, bonusAsset, _amount, interestRate, now, now + saveTime, false );
    }

    //finish the receipt and withdraw bonus and token
    function finishReceipt(uint256 _id) external notFinished(_id) exceedEndtime(_id) {
  
        //other processes

        //withdraw bonus and token
        //maybe more security check!!!!
        //保证要有足够的allowance
        uint256 bonusAmount = receipts[_id].amount.mul(receipts[_id].interestRate).div(100);    //percent rate of asset to bonus    1000elf->100 other token

        if (!ERC20(bonusAsset).transfer(receipts[_id].owner, bonusAmount )) throw;

        if (!ERC20(asset).transfer(receipts[_id].owner, receipts[_id].amount )) throw;

        //完成
        receipts[_id].finished = true;
    }


    function fixSaveTime(uint256 _period) external onlyOwner {
        saveTime = _period;
    }


}


library SafeMath {
    /**
     * @dev Returns the addition of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `+` operator.
     *
     * Requirements:
     * - Addition cannot overflow.
     */
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     */
    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    /**
     * @dev Returns the subtraction of two unsigned integers, reverting with custom message on
     * overflow (when the result is negative).
     *
     * Counterpart to Solidity's `-` operator.
     *
     * Requirements:
     * - Subtraction cannot overflow.
     *
     * _Available since v2.4.0._
     */
    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    /**
     * @dev Returns the multiplication of two unsigned integers, reverting on
     * overflow.
     *
     * Counterpart to Solidity's `*` operator.
     *
     * Requirements:
     * - Multiplication cannot overflow.
     */
    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    /**
     * @dev Returns the integer division of two unsigned integers. Reverts with custom message on
     * division by zero. The result is rounded towards zero.
     *
     * Counterpart to Solidity's `/` operator. Note: this function uses a
     * `revert` opcode (which leaves remaining gas untouched) while Solidity
     * uses an invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        // Solidity only automatically asserts when dividing by 0
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     */
    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    /**
     * @dev Returns the remainder of dividing two unsigned integers. (unsigned integer modulo),
     * Reverts with custom message when dividing by zero.
     *
     * Counterpart to Solidity's `%` operator. This function uses a `revert`
     * opcode (which leaves remaining gas untouched) while Solidity uses an
     * invalid opcode to revert (consuming all remaining gas).
     *
     * Requirements:
     * - The divisor cannot be zero.
     *
     * _Available since v2.4.0._
     */
    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}
