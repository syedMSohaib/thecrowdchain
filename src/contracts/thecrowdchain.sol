pragma solidity ^0.5.8;
// Importing OpenZeppelin's SafeMath Implementation
import 'https://github.com/OpenZeppelin/openzeppelin-solidity/contracts/math/SafeMath.sol';

contract TheCrowdChain {
    using SafeMath for uint256;

    Cause[] private causes;

    event CauseCreated(
        address causeAddress,
        address creator,
        string title,
        string cause_type,
        string desciption,
        uint256 goal
    );

    /* Function to create a new cause */
    function startCause(string calldata title, string calldata cause_type, string calldata description, uint goal) external{
        //creating an object for cause contract
        Cause newCauses = new Cause(msg.sender, title, cause_type, description, goal);

        //push in causes array created earlier
        causes.push(newCauses);

        //emit CauseCreated event
        emit CauseCreated(
            address(newCauses),
            msg.sender,
            title,
            cause_type,
            description,
            goal
        );
    }

    /* Function to list all the causes */
    function getAllCauses() external view returns(Cause[] memory ) {
        return causes;
    }
}


contract Cause{
    using SafeMath for uint256;

    //charity cause current status
    enum State {
        pending,
        completed
    }

    address payable public creator;
    uint public goal;
    uint256 public current;
    string public title;
    string public cause_type;
    string public description;

    State public state = State.pending;
    mapping(address => uint) public donors;

    //event when ever funding or donation is received
    event donationReceived(address donor, uint amount, uint current);

    //event when donation is completed and amount is dispatched
    event donationSentToTarget(address recipient);

    //check the current state via modifier
    modifier checkState(State state_){
        require(state == state_);
        _;
    }

    //check if caller is creator
    modifier isCreator(){
        require(msg.sender == creator);
        _;
    }

    constructor(
        address payable c_starter,
        string memory c_title,
        string memory c_type,
        string memory c_description,
        uint c_goal
    ) public {
        creator = c_starter;
        title = c_title;
        cause_type = c_type;
        description = c_description;
        goal = c_goal;
        current = 0;
    }

    /* Function to contribute/donate to cause*/
    function donate() external checkState(State.pending) payable{
        require(msg.sender != creator);
        donors[msg.sender] = donors[msg.sender].add(msg.value);
        current = current.add(msg.value);
        //emit donationReceived event
        emit donationReceived(msg.sender, msg.value, current);
        //check if donation is completed
        checkIfDonationCompleted();
    }

    function checkIfDonationCompleted() public {
        if(current >= goal){
            state = State.completed;
            payToTarget();
        }
    }

    function payToTarget() internal checkState(State.completed) returns (bool) {
        uint256 raised = current;
        current = 0;

        if(creator.send(raised)){
            emit donationSentToTarget(creator);
            return true;
        }
        else{
            current = raised;
            state = State.completed;
        }
        return false;
    }

    function get() public view returns
    (
        address payable c_starter,
        string memory c_title,
        string memory c_type,
        string memory c_description,
        State currentState,
        uint256 c_goal,
        uint256 c_raised
    ) {
        c_starter = creator;
        c_title = title;
        c_type = cause_type;
        currentState = state;
        c_description = description;
        c_goal = goal;
        c_raised = current;
    }
}
