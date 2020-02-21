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
    
    //using SafeMath for uint256;
    event NewReceipt(uint256 receiptId, address asset, uint256 endTime);

    CandyReceipt candyReceipt = CandyReceipt(0xbf2179859fc6d5bee9bf9158632dc51678a4100e);
    bytes32[] public leafNodes;
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
        
        //fetch users' lock datas
        uint256 leafCount = candyReceipt.receiptCount();
        
        //Hash all leaves
        for(uint256 i; i<leafCount; i++) {
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
            ) = candyReceipt.receipts(i);
            
            
            if(finished == false)
                leafNodes.push(sha256(abi.encodePacked(targetAddress,amount)));
            
        }
        
    }
    
    //create new receipt
    function GenerateMerkle() external {
        
        //fetch data and generate leaves
        ReceiptsToLeaves();
        
        uint256 leafCount = candyReceipt.receiptCount();
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
        
        
        
       
    }
    
    
}