// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.8.0 <0.9.0;

import {KickProject} from "./KickProject.sol";
import "hardhat/console.sol";

contract KickFactory {
    
    KickProject[] public projects;
    address kickBronze;
    address kickSilver;
    address kickGold;

    bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");

    constructor(address _kickBronze, address _kickSilver, address _kickGold) {
        kickBronze = _kickBronze;
        kickSilver = _kickSilver;
        kickGold = _kickGold;
    }
    
    // creates a new KickProject contract with sender as owner and provided goal, timeout period to reach it
    // and draw down interval and returns the contract's address
    function launchProject(uint _goal, uint _timeout, uint _drawDownInterval,
                           uint _bronze, uint _silver, uint _gold) public returns (address projectContractAddr) {
        require((_bronze < _silver) && (_silver < _gold), "bronze, silver, gold levels must be in ascending order");
        KickProject project = new KickProject(msg.sender, _goal, _timeout, _drawDownInterval,
                                              _bronze, kickBronze, _silver, kickSilver, _gold, kickGold);
        projects.push(project);
        return address(project);
    }

    function numProjects() public view returns (uint) {
        return projects.length;
    }
}
