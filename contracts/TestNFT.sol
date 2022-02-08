// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestNFT is Ownable, ERC721
{
    constructor() ERC721("TestNFT", "TNFT")
    {
        _mint(owner(), 1);
    }
    
    function mint(address account, uint token_id) public onlyOwner
    {
        _mint(account, token_id);
    }
}

