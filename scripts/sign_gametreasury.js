// Right click on the script name and hit "Run" to execute
(async () => {
    try {
        console.log('Running GameTreasury sign test...')
        const account = (await web3.eth.getAccounts())[0];

        console.log("address", account)

        const name = "GameTreasury";
        const version = "1.0";
        const chain_id = await web3.eth.getChainId();
        const contract_address = "0x00193cc2d32a27d7d6f99172f346ed58bc9b10a9";
        const salt = "0x0caaadd5fd4d8a10894f330ae16c94ab15949942ce2610697319e90402db033f";

        const token_address = "0xE6c471121b974dce211b65eF41E7E17D53Be879d";
        const nft_address = "0x6848d4fb6603a0254ef876070b078067a5f0e6c0";
        
        const domain_separator = domainSeparator(name, version, chain_id, contract_address, salt); 
        
//        console.log(domain_separator);
        var typed_data = toTypedDataHash(domain_separator, claimERC721Hash(nft_address, "0xF1F6720d4515934328896D37D356627522D97B49", 1, 2));
//        var typed_data = toTypedDataHash(domain_separator, claimERC20Hash(token_address, "0xF1F6720d4515934328896D37D356627522D97B49", 10, 1));
        console.log(typed_data);

        console.log( await web3.eth.sign(typed_data, account))
    
    } catch (e) {
        console.log(e.message)
    }
})()

function claimERC721Hash(erc721_address, to, tokenId, withdrawId)
{
//    console.log("claim nft type hash", web3.utils.keccak256(web3.utils.utf8ToHex("claimERC721(address to,address erc721_address,uint256 tokenId,uint256 withdrawId)")))
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32", "address", "address", "uint256", "uint256"], [
            web3.utils.keccak256(web3.utils.utf8ToHex("claimERC721(address to,address erc721_address,uint256 tokenId,uint256 withdrawId)")),
            to,
            erc721_address,
            tokenId,
            withdrawId
        ]));
}

function claimERC20Hash(erc20_address, to, amount, withdrawId)
{
//    console.log("claim erc20 type hash", web3.utils.keccak256(web3.utils.utf8ToHex("claimERC20(address to,address erc20_address,uint256 amount,uint256 withdrawId)")));
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32", "address", "address", "uint256", "uint256"], [
            web3.utils.keccak256(web3.utils.utf8ToHex("claimERC20(address to,address erc20_address,uint256 amount,uint256 withdrawId)")),
            to,
            erc20_address,           
            amount,
            withdrawId
        ]));
}

function domainSeparator(name, version, chainId, verifyingContract, salt)
{
    const type_hash = web3.utils.keccak256(web3.utils.utf8ToHex("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract,bytes32 salt)"));
    const name_hash = web3.utils.keccak256(web3.utils.utf8ToHex(name));
    const version_hash = web3.utils.keccak256(web3.utils.utf8ToHex(version));
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32", "bytes32", "bytes32", "uint256", "address", "bytes32"], [type_hash, name_hash, version_hash, chainId, verifyingContract, salt])); 
}

function toTypedDataHash(domainSeparator, structHash)
{
    return web3.utils.keccak256(web3.utils.encodePacked("\x19\x01", domainSeparator, structHash));
}