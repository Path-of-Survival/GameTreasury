// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./access/AdminPrivileges.sol";
import "./cryptography/EIP712.sol";

interface IPoSNFT
{
    function mintByAdmin(address to, uint token_id) external;
    function mintByAdmin(address to, uint token_id, uint[] memory metadata) external;
}

contract GameTreasury is AdminPrivileges, EIP712, ERC721Holder
{
    using SafeERC20 for IERC20;

    mapping(uint=>bool) private withdraw_ids;
    bytes32 constant private CLAIM_ERC20_TYPE_HASH = 0xea348efde5622ad29c55ef03a95167ea9fb6d2512dff03cffda98339c786bf56;
    bytes32 constant private CLAIM_ERC721_TYPE_HASH = 0xc8066efde1cf94c6fbfd2d8a44d68c0505a867bc075e2a1019b483e12ae3228a;
    bytes32 constant private MINT_TYPE_HASH = 0xc792717ac7924b7fba148e24b5244a71f5f6ea777d9fbd8c6fda825ba8f187ab;
    bytes32 constant private MINT_METADATA_TYPE_HASH = 0xcc6fb495d18c2f4149eb2409d4c09954d40ad7f329ac3cbfaac1e30fddc0cfa7;

    event TokensDeposited(address _from, address _contract_address, uint _amount);
    event TokensWithdrawn(address _to, address _contract_address, uint _amount, uint _withdrawId);
    event NFTDeposited(address _from, address _contract_address, uint _tokenId);
    event NFTWithdrawn(address _to, address _contract_address, uint _tokenId, uint _withdrawId);
    event WithdrawRequestCancelled(uint _withdrawId);

    constructor(bytes32 salt) EIP712("GameTreasury", "1.0", salt)
    { }
    
    function depositERC20(address erc20_address, uint amount) public
    {
        IERC20 token = IERC20(erc20_address);
        token.safeTransferFrom(_msgSender(), address(this), amount);
        emit TokensDeposited(_msgSender(), erc20_address, amount);
    }

    function depositERC721(address erc721_address, uint tokenId) public
    {
        IERC721 token = IERC721(erc721_address);
        token.safeTransferFrom(_msgSender(), address(this), tokenId);
        emit NFTDeposited(_msgSender(), erc721_address, tokenId);
    }

    function mint(address posnft_address, uint tokenId, uint withdrawId, bytes memory signature) external
    {
        bytes32 data_hash = keccak256(abi.encode(MINT_TYPE_HASH, _msgSender(), posnft_address, tokenId, withdrawId));
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        require(isAdmin(EIP712.verify(data_hash, signature)) == true, "invalid signature");
        IPoSNFT posnft = IPoSNFT(posnft_address);
        posnft.mintByAdmin(_msgSender(), tokenId);
        withdraw_ids[withdrawId] = true;
        emit NFTWithdrawn(_msgSender(), posnft_address, tokenId, withdrawId);
    }

    function mintWithMetadata(address posnft_address, uint tokenId, uint256[] memory metadata, uint withdrawId, bytes memory signature) external
    {
        bytes32 data_hash = keccak256(abi.encode(MINT_METADATA_TYPE_HASH, _msgSender(), posnft_address, tokenId, keccak256(abi.encodePacked(metadata)), withdrawId));
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        require(isAdmin(EIP712.verify(data_hash, signature)) == true, "invalid signature");
        IPoSNFT posnft = IPoSNFT(posnft_address);
        posnft.mintByAdmin(_msgSender(), tokenId, metadata);
        withdraw_ids[withdrawId] = true;
        emit NFTWithdrawn(_msgSender(), posnft_address, tokenId, withdrawId);
    }

    function claimERC20(address erc20_address, uint amount, uint withdrawId, bytes memory signature) external
    {
        bytes32 data_hash = keccak256(abi.encode(CLAIM_ERC20_TYPE_HASH, _msgSender(), erc20_address, amount, withdrawId));
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        require(isAdmin(EIP712.verify(data_hash, signature)) == true, "invalid signature");
        IERC20 token = IERC20(erc20_address);
        token.transfer(_msgSender(), amount);
        withdraw_ids[withdrawId] = true;
        emit TokensWithdrawn(_msgSender(), erc20_address, amount, withdrawId);
    }

    function claimERC721(address erc721_address, uint tokenId, uint withdrawId, bytes memory signature) external
    {
        bytes32 data_hash = keccak256(abi.encode(CLAIM_ERC721_TYPE_HASH, _msgSender(), erc721_address, tokenId, withdrawId));
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        require(isAdmin(EIP712.verify(data_hash, signature)) == true, "invalid signature");
        IERC721 nft = IERC721(erc721_address);
        nft.safeTransferFrom(address(this), _msgSender(), tokenId);
        withdraw_ids[withdrawId] = true;
        emit NFTWithdrawn(_msgSender(), erc721_address, tokenId, withdrawId);
    }

    function cancelWithdrawERC20(address erc20_address, uint amount, uint withdrawId, bytes memory signature) external
    {
        bytes32 data_hash = keccak256(abi.encode(CLAIM_ERC20_TYPE_HASH, _msgSender(), erc20_address, amount, withdrawId));
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        require(isAdmin(EIP712.verify(data_hash, signature)) == true, "invalid signature");
        withdraw_ids[withdrawId] = true;
        emit WithdrawRequestCancelled(withdrawId);
    }

    function cancelWithdrawERC721(address erc721_address, uint tokenId, uint withdrawId, bytes memory signature) external
    {
        bytes32 data_hash = keccak256(abi.encode(CLAIM_ERC721_TYPE_HASH, _msgSender(), erc721_address, tokenId, withdrawId));
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        require(isAdmin(EIP712.verify(data_hash, signature)) == true, "invalid signature");
        withdraw_ids[withdrawId] = true;
        emit WithdrawRequestCancelled(withdrawId);
    }

    function cancelMint(address posnft_address, uint tokenId, uint withdrawId, bytes memory signature) external
    {
        bytes32 data_hash = keccak256(abi.encode(MINT_TYPE_HASH, _msgSender(), posnft_address, tokenId, withdrawId));
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        require(isAdmin(EIP712.verify(data_hash, signature)) == true, "invalid signature");
        withdraw_ids[withdrawId] = true;
        emit WithdrawRequestCancelled(withdrawId);
    }

    function cancelMintWithMetadata(address posnft_address, uint tokenId, uint256[] memory metadata, uint withdrawId, bytes memory signature) external
    {
        bytes32 data_hash = keccak256(abi.encode(MINT_METADATA_TYPE_HASH, _msgSender(), posnft_address, tokenId, keccak256(abi.encodePacked(metadata)), withdrawId));
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        require(isAdmin(EIP712.verify(data_hash, signature)) == true, "invalid signature");
        withdraw_ids[withdrawId] = true;
        emit WithdrawRequestCancelled(withdrawId);
    }
}
