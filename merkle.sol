pragma solidity ^0.4.24;
pragma experimental ABIEncoderV2;

contract CandyReceipt {

  Receipt[] public receipts;
  uint256 public receiptCount;
  
  struct Receipt {

        address asset;      //token to deposit  ELF:0xbf2179859fc6d5bee9bf9158632dc51678a4100e
        address owner;      //owner of this receipt
        string targetAddress;
        address bonusAsset;
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;      
        uint256 endTime;
        bool finished; 

    }
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


contract MerkleTreeGenerator is Owned {
    
    using SafeMath for uint256;
    event Log(bytes data);

    CandyReceipt candyReceipt = CandyReceipt(0xEC665a4d1133E27c3513c69310242AF4CE0F9d0C);
    uint256 public currentIndex = 0;
    bytes32[] public leafNodes;         //always empty
    MerkleTree[] public merkleTrees;
    

    struct MerkleTree {

        bytes32[] nodes;
        bytes32 root;
        uint256 leaf_count;    
        uint block; //block height when created
    }
    
    struct MerkleNode {

        bytes32 hash;
        bool is_left_child_node;    

    }
    
    struct MerklePath {
        MerkleNode[] merkle_path_nodes;
    }
    
    struct Receipt {

        address asset;      //token to deposit  ELF:0xbf2179859fc6d5bee9bf9158632dc51678a4100e
        address owner;      //owner of this receipt
        string targetAddress;
        address bonusAsset;
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;      
        uint256 endTime;
        bool finished; 

    }
    
    
    
    //fetch receipts
    function ReceiptsToLeaves() internal{
        
        //clean the leafNodes
        delete leafNodes;
        
        uint256 receiptCount = candyReceipt.receiptCount();
        //fetch users' lock datas from currentIndex
        //this leafCount include finished receipts
        uint256 leafCount = receiptCount.sub(currentIndex);
        
        //no more than 1023 leaves in a tree
        leafCount = leafCount > 1023 ? 1023 : leafCount;
        
        assert(leafCount > 0);
        
        //Hash all leaves
        for(uint256 i=0; i<leafCount; i++) {
            (
                address asset,
                address owner,
                string memory targetAddress,
                address bonusAsset,
                uint256 amount,
                uint256 interestRate,
                uint256 startTime,
                uint256 endTime,
                bool finished 
            ) = candyReceipt.receipts(currentIndex + i);
            
            
            if(finished == false) {
                //leafNodes.push(sha256(abi.encodePacked(amount, targetAddress)));
                leafNodes.push(sha256(sha256(amount), sha256(targetAddress),sha256(currentIndex + i)));
                Log(abi.encodePacked(sha256(amount), sha256(targetAddress), sha256(currentIndex + i)));
            }
            
        }
        
        currentIndex += leafCount;
        
    }
    
    //create new receipt
    function GenerateMerkleTree() external {
        
        //fetch data and generate leaves
        ReceiptsToLeaves();
        
        //this leafCount doesn't include finished receipts
        uint256 leafCount = leafNodes.length;
        bytes32 left;
        bytes32 right;
        uint256 nodeToAdd = leafNodes.length / 2;
        uint256 newAdded = 0;
        uint256 i = 0;
        
        
        //make sure the number of leaves is even
        if(leafNodes.length % 2 == 1) {
            leafNodes.push(leafNodes[leafNodes.length - 1]);
        }
        
        //generate branch nodes
        while( i < leafNodes.length - 1) {
            
            left = leafNodes[i++];
            right = leafNodes[i++];
            //leafNodes.push(sha256(abi.encodePacked(left,right)));
            leafNodes.push(sha256(left,right));
            if (++newAdded != nodeToAdd)
                continue;

            // complete this row
            if (nodeToAdd % 2 == 1 && nodeToAdd != 1)
            {
                nodeToAdd++;
                leafNodes.push(leafNodes[leafNodes.length - 1]);
            }

            // start a new row
            nodeToAdd /= 2;
            newAdded = 0;
        }
        
        
        //save to merkleTrees
        merkleTrees.push(MerkleTree(leafNodes, leafNodes[leafNodes.length - 1], leafCount, block.number));
        
        //clean leafNodes
        delete leafNodes;
       
    }
    function GetNodes(uint256 index) public view returns(bytes32[]) {
        
        return merkleTrees[index].nodes;
    }
    function GetReceipt(uint256 index) public view returns(bytes, bytes32) {
        (
                address asset,
                address owner,
                string memory targetAddress,
                address bonusAsset,
                uint256 amount,
                ,
                ,
                ,
                bool finished 
        ) = candyReceipt.receipts(index);
            
        //return (abi.encodePacked(amount, targetAddress),sha256(abi.encodePacked(amount, targetAddress)));
        return (abi.encodePacked(sha256(amount), sha256(targetAddress), sha256(index)), sha256(sha256(amount), sha256(targetAddress), sha256(index)));
    }
    //get users merkle tree path
    function GenerateMerklePath(uint256 index) public view returns(bytes32[20],bool[20]) {
        
        assert(index < currentIndex);
        //need to locate which MerkleTree include target index receipt
        
  
        uint256 indices = 0;
        uint256 j = 0;

     
        do{
            indices = indices.add(merkleTrees[j++].leaf_count);
        } while(index >= indices);
        
        index = index.sub(indices.sub(merkleTrees[--j].leaf_count));      //convert to relative index

        
        MerkleTree memory merkleTree = merkleTrees[j]; 
        
        assert(index < merkleTree.leaf_count);

        bytes32[20] memory neighbors;// = new bytes32[](20) ;
        bool[20] memory isLeftNeighbors;
        uint256 indexOfFirstNodeInRow = 0;
        uint256 nodeCountInRow = merkleTree.leaf_count;
        bytes32 neighbor;
        bool isLeftNeighbor;
        uint256 shift;
        uint256 i = 0;
        
       
        
        while (index < merkleTree.nodes.length - 1) {
            
            
            if (index % 2 == 0)
            {
                // add right neighbor node
                neighbor = merkleTree.nodes[index + 1];
                isLeftNeighbor = false;
            }
            else
            {
                // add left neighbor node
                neighbor = merkleTree.nodes[index - 1];
                isLeftNeighbor = true;
            }
            
            neighbors[i] = neighbor;
            isLeftNeighbors[i++] = isLeftNeighbor;
            
            nodeCountInRow = nodeCountInRow % 2 == 0 ? nodeCountInRow : nodeCountInRow + 1;
            shift = (index - indexOfFirstNodeInRow) / 2;
            indexOfFirstNodeInRow += nodeCountInRow;
            index = indexOfFirstNodeInRow + shift;
            nodeCountInRow /= 2;
            
        }
        
        
        return (neighbors,isLeftNeighbors);

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