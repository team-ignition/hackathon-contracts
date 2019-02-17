pragma solidity 0.4.24;

contract Hackathon {
    using SafeMath for uint256;
     
    event VotesBought(address indexed _recipient, uint256 _amount, uint256 _periodIndex);
    event Vote(address indexed _voterAddress, address indexed _candidateAddress, uint256 _amount, uint256 _periodIndex);

    address public token; // DAI Smart Contract
    uint256 public nonce;


    struct Hackathon {
        uint256 start_ts;
        uint256 end_ts;
        address juryRegistry;
        address candidateRegistry;
        uint256[] weights;
    }
    
    mapping (uint256 => Hackathon) public hackathons; 
    mapping (uint256 => uint256[]) public voteStack;
    mapping (uint256 => mapping(address => uint256)) public votesReceived;
    mapping (uint256 => mapping(address => uint256)) public votesBalance;
    mapping (uint256 => uint256) public balance;
    

    function newHackathon(uint256 _start_ts, uint256 _end_ts, uint256[] _weights) {
        require(_start_ts > _end_ts);
        OwnedRegistry juryRegistry = new OwnedRegistry();
        OwnedRegistry candidateRegistry = new OwnedRegistry();
        hackathons[nonce + 1] = Hackathon(_start_ts, _end_ts, juryRegistry, candidateRegistry, _weights);  
    }

    function setTokenAddress(address _token){
        token = _token;
    }
    
    function setJuryRegistry(uint256 _id, address _juryRegistry) public {
        hackathons[_id].juryRegistry = _juryRegistry; 
    }

    function setCandidateRegistry(uint256 _id, address _candidateRegistry) public {
        hackathons[_id].candidateRegistry = _candidateRegistry; 
    }
    

    /**
    * @dev Exchanges the main token for an amount of votes
    * @param _amount Amount of votes that the voter wants to buy
    * NOTE: Requires previous allowance of expenditure of at least the amount required, right now 1:1 exchange used
    **/

    function buyTokenVotes(uint256 _amount, uint256 id) external {
        require(ERC20(TOKEN).transferFrom(msg.sender, this, _amount));
        votesBalance[id][msg.sender] += _amount;
        emit VotesBought(msg.sender, _amount, 0);
    }


    /**
    * @dev Adds a new vote for a candidate
    * @param _candidateAddress address of the candidate selected
    * @param _amount of votes used
    */
 

    function vote(uint256 _id, address _candidateAddress, uint256 _amount) external {
        require(OwnedRegistry(hackathons[_id].juryRegistry).isWhitelisted(msg.sender));
        require(OwnedRegistry(hackathons[_id].candidatesRegistry).isWhitelisted(_candidateAddress));
        require(votesBalance[_id][msg.sender] >= _amount);
        votesReceived[_id][_candidateAddress] = votesReceived[_id][_candidateAddress].add(_amount);
        votesBalance[_id][msg.sender] -= _amount;
        emit Vote(msg.sender, _candidateAddress, _amount, _id);
    }
    
    function getRank(address _account, uint256 _id) public view returns (uint256) {
        OwnedRegistry candidates = OwnedRegistry(hackathons[_id].candidateRegistry);
        uint256 rank = candidates.getLog().length;
        for (uint i = 0; i < candidates.getLog().length; i++){
            if (votesBalance[_id][_account] >= votesBalance[_id][candidates.getLog()[i]]) {
                rank --;
            }
        }
        return rank;
    }
}
