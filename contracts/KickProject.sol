// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

//import "hardhat/console.sol";

abstract contract MedalInterface {
    function mint(address recipient) public virtual;
}

contract KickProject {

    // Storage
    
    MedalInterface kickBronze;
    MedalInterface kickSilver;
    MedalInterface kickGold;
    
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

    // records which NFTs have been awarded
    mapping(address => uint) public nfts;

    // current total of all contributions
    uint public amountCollected;

    // minimum contribution to achieve bronze token
    uint bronze;
    
    // minimum contribution to achieve silver token
    uint silver;
    
    // minimum contribution to achieve gold token
    uint gold;

    uint constant minContribution = 0.01 ether;

    //functions
    
    // Sets the owner to _owner, goal to _goal, drawDownInterval to _drawDownInterval and deadline to current time plus the timeout
    //
    constructor(address _owner, uint _goal, uint _timeout, uint _drawDownInterval, uint _bronze, address _bronzeAddress, uint _silver, address _silverAddress, uint _gold, address _goldAddress) {
        require(_goal >= minContribution, "Goal must at least equal minimum contribution");
        owner = _owner;
        goal = _goal;
        deadline = block.timestamp + _timeout;
        drawDownInterval = _drawDownInterval;
        bronze = _bronze;
        kickBronze = MedalInterface(_bronzeAddress);
        silver = _silver;
        kickSilver = MedalInterface(_silverAddress);
        gold = _gold;
        kickGold = MedalInterface(_goldAddress);
    }
    
    // Checks project not cancelled, funds > 0.01 eth, and goal not yet met, rejects if not, 
    // otherwise accepts funds and records sender in contributions
    // updating their amount contributed if they have previously contributed
    // or adding a new mapping for them if this is their first contribution
    function contribute() public payable {
        if (cancelled) {
            revert("Project cancelled");
        }
        if (block.timestamp >= deadline) {
            revert("Deadline reached");
        }
        if (amountCollected >= goal) {
            revert("Project goal met");
        }
        uint contribution = msg.value;
        if (contribution < minContribution) {
            revert("Min contribution 0.01 ether");
        }
        contributions[msg.sender] += contribution;
        amountCollected += contribution;
        if (amountCollected >= goal) {
            whenGoalReached = block.timestamp;
        }
        if ((contributions[msg.sender] >= bronze) && (nfts[msg.sender] < 1)) {
            kickBronze.mint(msg.sender);
            nfts[msg.sender] = 1;
        }
        if ((contributions[msg.sender] >= silver) && (nfts[msg.sender] < 2)) {
            kickSilver.mint(msg.sender);
            nfts[msg.sender] = 2;
        }
        if ((contributions[msg.sender] >= gold) && (nfts[msg.sender] < 3)) {
            kickGold.mint(msg.sender);
            nfts[msg.sender] = 3;
        }
    }
    
    // rejects with request to use the contribute function
    receive() external payable {
        revert("Please call contribute");
    }
    
    // checks that no funds have yet been drawn down, rejects if they have, otherwise sets cancelled to true
    function cancel() public onlyOwner {
        if (drawnDown > 0) {
            revert("funds drawn down");
        }
        cancelled = true;
    }
    
    // checks that sender made a contribution and either deadline has passed and goal has not been met or project has been cancelled,
    // if so updates sender's contribution to zero and sends their funds back to them
    function withdrawContribution() public  {
        uint contribution = contributions[msg.sender];
        if (contribution == 0) {
            revert("No contribution made");
        }
        if (!cancelled) {
            if (block.timestamp < deadline) {
                revert("still open");
            }
            if (amountCollected >= goal) {
                revert("reached goal");
            }
        }
        contributions[msg.sender] = 0;
        amountCollected -= contribution;
        (bool sent, ) = msg.sender.call{value: contribution}("");
        require(sent, "Failed to send");
    }
    
    // checks that goal is met, and project has not been cancelled and funds contributed minus funds already drawn down exceeds or equals amount requested, 
    // if so updates drawnDown then transfers requested amount to owner, otherwise rejects
    function drawDownFunds(uint _amount) public onlyOwner {
        if (cancelled) {
            revert("Cancelled");
        }
        if (amountCollected < goal) {
            revert("Goal not met");
        }
        uint amountAvailableNow = calcAmountAvailableNow();
        if (amountAvailableNow < _amount) {
            revert("Insufficient funds");
        }
        drawnDown += _amount;
        (bool sent, ) = owner.call{value: _amount}("");
        require(sent, "Failed to send");
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
        require(msg.sender == owner, "Owner only");
        _;
    }

}
    
