// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import {KickProject} from "./KickProject.sol";
//import "hardhat/console.sol";

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
