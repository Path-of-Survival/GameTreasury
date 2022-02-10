// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "./EIP712.sol";


contract TestNFT is ERC721, EIP712
{
    address public admin;
    
    bytes32 immutable private MINT_TYPE_HASH = 0x4be54700c1c588568e41c1f2f24fd476dee9ec8f1e71f088d4a8e24bda925241; 
    mapping(uint => bool) private withdraw_ids;

    event Mint(address _to, uint tokenId, uint _withdrawId);
    event WithdrawRequestCancelled(uint _withdrawId);

    constructor() ERC721("TestNFT", "TNFT") EIP712("TestNFT", "1.0", 0x58af7b5043c35f089c99b49c810a9708a9e3adf6e16f94503cad160c62c64408)
    {
        admin = _msgSender();
    }

    function mintHash(address to, uint tokenId, uint withdrawId) pure internal returns(bytes32)
    {
        return keccak256(abi.encode(MINT_TYPE_HASH, to, tokenId, withdrawId));
    }

    function mint(uint tokenId, uint withdrawId, bytes memory signature) public
    {
        require(withdraw_ids[withdrawId] == false && admin == EIP712.verify(mintHash(_msgSender(), tokenId, withdrawId), signature), "invalid signature");
        _mint(_msgSender(), tokenId);
        withdraw_ids[withdrawId] = true;
        emit Mint(_msgSender(), tokenId, withdrawId);
    }

    function cancelMint(uint tokenId, uint withdrawId, bytes memory signature) public
    {
        require(withdraw_ids[withdrawId] == false && admin == EIP712.verify(mintHash(_msgSender(), tokenId, withdrawId), signature), "invalid signature");
        withdraw_ids[withdrawId] = true;
        emit WithdrawRequestCancelled(withdrawId);
    }
}