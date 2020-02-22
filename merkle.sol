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
    event Log(bytes data);

    CandyReceipt candyReceipt = CandyReceipt(0xb1DB8f1834ab5034142240f3bF615a3D703cBefa);
    bytes32[] public leafNodes;         //always empty
    //MerkleNode[] public merkleNodes;    //always empty
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
            
            
            if(finished == false) {
                leafNodes.push(sha256(abi.encodePacked(targetAddress,amount)));
                Log(abi.encodePacked(targetAddress,amount));
            }
            
        }
        
    }
    
    //create new receipt
    function GenerateMerkleTree() external {
        
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
        
        //clean leafNodes
        delete leafNodes;
       
    }
    function GetReceipt(uint256 index) public view returns(bytes) {
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
        ) = candyReceipt.receipts(index);
            
        return abi.encodePacked(targetAddress,amount);
    }
    //get users merkle tree path
    function GenerateMerklePath(uint256 index) public view returns(bytes32[20],bool[20]) {
        
        MerkleTree memory merkleTree = merkleTrees[merkleTrees.length - 1]; //先从最新的获取吧
        
        assert(index < merkleTree.leaf_count);

        bytes32[20] neighbors;
        bool[20] isLeftNeighbors;
        
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
            //merkleNodes[i++] = MerkleNode(neighbor, isLeftNeighbor);
            
            nodeCountInRow = nodeCountInRow % 2 == 0 ? nodeCountInRow : nodeCountInRow + 1;
            shift = (index - indexOfFirstNodeInRow) / 2;
            indexOfFirstNodeInRow += nodeCountInRow;
            index = indexOfFirstNodeInRow + shift;
            nodeCountInRow /= 2;
            
        }
        
        
        
        return (neighbors,isLeftNeighbors);

    }
    
    
}