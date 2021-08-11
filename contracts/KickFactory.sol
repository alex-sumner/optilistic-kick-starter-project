// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//import "hardhat/console.sol";

contract KickProject {

    // Storage
    
    // the address of the contract itself
    address public projectAddr;
    
    // the creator of the project
    address public owner;
    
    // the goal for total funds contributed
    uint public goal;
    
    // how quickly can the creator draw the funds once goal is met? 
    // If 0 then can take it all immediately, if n > 0 then can only take out 10% in the first period of n, 
    // another 10% in the next n, etc. so can't draw all funds out until time of 9n has passed
    uint public drawDownInterval;
    
    // the time at which the contributions reached the goal amount, zero if that hasn't happened yet
    uint public whenGoalReached;
    
    // the deadline by which contributions must reach the goal
    uint public deadline;
    
    // has the project been cancelled by the creator?
    bool public cancelled;
    
    // contributions withdrawn by creator so far
    uint public drawnDown;
    
    //records total contribution by address of contributor
    mapping(address => uint) public contributions;
    
    //current total of all contributions
    uint public amountCollected;
    
    //functions
    
    // Sets the owner to _owner, goal to _goal, drawDownInterval to _drawDownInterval and deadline to current time plus the timeout
    //
    constructor(address _owner, uint _goal, uint _timeout, uint _drawDownInterval) {
        owner = _owner;
        goal = _goal;
        deadline = block.timestamp + _timeout;
        drawDownInterval = _drawDownInterval;
        projectAddr = address(this);
        // console.log("constructor time %s deadline %s", block.timestamp, deadline);
    }
    
    // Checks project not cancelled, funds > 0.01 eth, and goal not yet met, rejects if not, 
    // otherwise accepts funds and records sender in contributions
    // updating their amount contributed if they have previously contributed
    // or adding a new mapping for them if this is their first contribution
    function contribute() public payable {
        // console.log("contribute time %s deadline %s", block.timestamp, deadline);
        if (cancelled) {
            revert("Project has been cancelled");
        }
        if (block.timestamp >= deadline) {
            revert("Project deadline has been reached");
        }
        if (amountCollected >= goal) {
            revert("Project goal has been met, contributions are no longer accepted");
        }
        uint contribution = msg.value;
        if (contribution < 0.01 ether) {
            revert("Minimum contribution is 0.01 ether");
        }
        contributions[msg.sender] += contribution;
        amountCollected += contribution;
        if (amountCollected >= goal) {
            whenGoalReached = block.timestamp;
        }
    }
    
    // rejects with request to use the contribute function
    receive() external payable {
        revert("Please call the contribute function to make a contribution");
    }
    
    // checks that no funds have yet been drawn down, rejects if they have, otherwise sets cancelled to true
    function cancel() public onlyOwner {
        if (drawnDown > 0) {
            revert("Cannot cancel after funds have been drawn down");
        }
        cancelled = true;
    }
    
    // checks that sender made a contribution and either deadline has passed and goal has not been met or project has been cancelled,
    // if so updates sender's contribution to zero and sends their funds back to them
    function withdrawContribution() public  {
        uint contribution = contributions[msg.sender];
        if (contribution == 0) {
            revert("Cannot withdraw contribution, sender has not made a contribution");
        }
        if (!cancelled) {
            if (block.timestamp < deadline) {
                revert("Cannot withdraw contribution, project is still open for contributions");
            }
            if (amountCollected >= goal) {
                revert("Cannot withdraw contribution, project has reached its goal");
            }
        }
        contributions[msg.sender] = 0;
        amountCollected -= contribution;
        (bool sent, ) = msg.sender.call{value: contribution}("");
        require(sent, "Failed to send Ether");
    }
    
    // checks that goal is met, and project has not been cancelled and funds contributed minus funds already drawn down exceeds or equals amount requested, 
    // if so updates drawnDown then transfers requested amount to owner, otherwise rejects
    function drawDownFunds(uint _amount) public onlyOwner {
        if (cancelled) {
            revert("Project has been cancelled");
        }
        if (amountCollected < goal) {
            revert("Project goal has not been met");
        }
        uint amountAvailableNow = calcAmountAvailableNow();
        if (amountAvailableNow < _amount) {
            revert("Insufficient funds available");
        }
        drawnDown += _amount;
        (bool sent, ) = owner.call{value: _amount}("");
        require(sent, "Failed to send Ether");
    }
    
    function calcAmountAvailableNow() private view returns (uint) {
        if (whenGoalReached == 0 || block.timestamp < whenGoalReached) {
            return 0;
        }
        if (drawDownInterval == 0) {
            return amountCollected - drawnDown;
        }
        uint intervalsSinceGoalReached = ((block.timestamp - whenGoalReached) / drawDownInterval) + 1;
        if (intervalsSinceGoalReached > 10) {
            intervalsSinceGoalReached = 10;
        }
        return ((amountCollected * intervalsSinceGoalReached) / 10) - drawnDown;
    }
        
    modifier onlyOwner {
        require(msg.sender == owner, "Only owner can call this function.");
         _;
    }

}
    
contract KickFactory {
    
    KickProject[] public projects;
    
    //creates a new KickProject contract with sender as owner and provided goal, timeout period to reach it and draw down interval and returns the contract's address
    function launchProject(uint _goal, uint _timeout, uint _drawDownInterval) public returns (address projectContractAddr) {
        KickProject project = new KickProject(msg.sender, _goal, _timeout, _drawDownInterval);
        projects.push(project);
        return (project.projectAddr());
    }

    function numProjects() public view returns (uint) {
        return projects.length;
    }
}

