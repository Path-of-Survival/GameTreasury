// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

import "./MetadataStruct.sol";

interface IPoSNFT
{
    function mintByAdmin(address to, uint token_id) external;
    function mintByAdmin(address to, uint token_id, uint[] memory metadata) external;
    function burn(uint token_id) external;
    function getMetadata(uint token_id) external returns(MetadataStruct memory);
}

contract GameTreasury is Ownable, ERC721Holder
{
    using SafeERC20 for IERC20;

    mapping(uint=>bool) private withdraw_ids;

    event TokensDeposited(address _from, address _contract_address, uint _amount);
    event TokensWithdrawn(address _to, address _contract_address, uint _amount, uint _withdrawId);
    event NFTDeposited(address _from, address _contract_address, uint _token_id, MetadataStruct _metadata);
    event NFTWithdrawn(address _to, address _contract_address, uint _token_id, uint _withdrawId);
    event WithdrawRequestCancelled(uint _withdrawId);

    constructor()
    { }
    
    function depositERC20(address erc20_address, uint amount) public
    {
        IERC20 token = IERC20(erc20_address);
        token.safeTransferFrom(_msgSender(), address(this), amount);
        emit TokensDeposited(_msgSender(), erc20_address, amount);
    }

    function depositAndLockERC721(address erc721_address, uint token_id) public
    {
        IERC721 nft_smc = IERC721(erc721_address);
        nft_smc.safeTransferFrom(_msgSender(), address(this), token_id);
        emit NFTDeposited(_msgSender(), erc721_address, token_id, MetadataStruct("", new bytes(0)));
    }

    function depositAndBurnERC721(address erc721_address, uint token_id) public
    {
        IPoSNFT nft_smc = IPoSNFT(erc721_address);
        MetadataStruct memory nft_metadata = nft_smc.getMetadata(token_id);
        nft_smc.burn(token_id);
        emit NFTDeposited(_msgSender(), erc721_address, token_id, nft_metadata);
    }

    function mint(address posnft_address, uint token_id, uint withdrawId) external onlyOwner
    {      
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        IPoSNFT posnft = IPoSNFT(posnft_address);
        posnft.mintByAdmin(_msgSender(), token_id);
        withdraw_ids[withdrawId] = true;
        emit NFTWithdrawn(_msgSender(), posnft_address, token_id, withdrawId);
    }

    function mintWithMetadata(address posnft_address, uint token_id, uint256[] memory metadata, uint withdrawId) external onlyOwner
    {
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        IPoSNFT posnft = IPoSNFT(posnft_address);
        posnft.mintByAdmin(_msgSender(), token_id, metadata);
        withdraw_ids[withdrawId] = true;
        emit NFTWithdrawn(_msgSender(), posnft_address, token_id, withdrawId);
    }

    function claimERC20(address erc20_address, uint amount, uint withdrawId) external onlyOwner
    {
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        IERC20 token = IERC20(erc20_address);
        token.transfer(_msgSender(), amount);
        withdraw_ids[withdrawId] = true;
        emit TokensWithdrawn(_msgSender(), erc20_address, amount, withdrawId);
    }

    function claimERC721(address erc721_address, uint token_id, uint withdrawId) external onlyOwner
    {
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        IERC721 nft_smc = IERC721(erc721_address);
        nft_smc.safeTransferFrom(address(this), _msgSender(), token_id);
        withdraw_ids[withdrawId] = true;
        emit NFTWithdrawn(_msgSender(), erc721_address, token_id, withdrawId);
    }

    function cancelWithdrawRequest(uint withdrawId) external onlyOwner
    {
        require(withdraw_ids[withdrawId] == false, "invalid withdrawId");
        withdraw_ids[withdrawId] = true;
        emit WithdrawRequestCancelled(withdrawId);
    }

}
