pragma solidity ^0.4.18;

contract CandyReceipt {
    
  Receipt[] public receipts;
  uint256 public receiptCount;
  
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

    address public asset = 0xbf2179859fc6d5bee9bf9158632dc51678a4100e;
    uint256 public saveTime = 86400; //1 days;
    CandyReceipt candyReceipt = CandyReceipt(0xbf2179859fc6d5bee9bf9158632dc51678a4100e);

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
        address bonusAsset;
        uint256 amount;
        uint256 interestRate;
        uint256 startTime;      
        uint256 endTime;
        bool finished; 

    }
    
    MerkleTree[] public merkleTrees;
    
    
    //create new receipt
    function GenerateMerkle() external {
  

        //fetch users' lock datas
        uint256 leafCount = candyReceipt.receiptCount();
        bytes32[] leafNodes;
        
        //Hash all leaves
        for(uint256 i; i<leafCount; i++) {
            (
            address asset,
            address owner,
            address bonusAsset,
            uint256 amount,
            uint256 interestRate,
            uint256 startTime,
            uint256 endTime,
            bool finished 
            
            ) = candyReceipt.receipts(i);
            
            string memory data = "123";
            
            leafNodes.push(sha256(owner,amount));
            
        }

        //
        
        
        
        
    }
    
    
}