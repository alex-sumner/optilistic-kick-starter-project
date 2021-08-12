// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import {KickBronze} from "./KickBronze.sol";
import {KickSilver} from "./KickSilver.sol";
import {KickGold} from "./KickGold.sol";

contract NFTHandler {

    address public owner;
    KickBronze bronzeNFT;
    KickSilver silverNFT;
    KickGold goldNFT;
    
    constructor() {
        owner = msg.sender;
        bronzeNFT = new KickBronze();
        silverNFT = new KickSilver();
        goldNFT = new KickGold();
    }
    
    function award(address _recipient, bool _giveBronze, bool _giveSilver, bool _giveGold) public onlyOwner {
        if (_giveBronze) {
            bronzeNFT.mint(_recipient);
        }
        if (_giveSilver) {
            silverNFT.mint(_recipient);
        }
        if (_giveGold) {
            goldNFT.mint(_recipient);
        }
    }
    
    modifier onlyOwner {
        require(msg.sender == owner, "Owner only");
        _;
    }

}

