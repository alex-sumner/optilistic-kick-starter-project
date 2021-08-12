 // SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.7.0 <0.9.0;

import "@openzeppelin/contracts/token/ERC721/presets/ERC721PresetMinterPauserAutoId.sol";

contract KickSilver is ERC721PresetMinterPauserAutoId {
    constructor() ERC721PresetMinterPauserAutoId("Silver", "KST", "") {
    }
}

