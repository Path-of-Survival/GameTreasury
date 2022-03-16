// Right click on the script name and hit "Run" to execute
(async () => {
    try {
        console.log('Running PoSNFT sign test...')
        const account = (await web3.eth.getAccounts())[0];

        console.log("address", account)

        const name = "PoSNFT";
        const version = "1.0";
        const chain_id = await web3.eth.getChainId();
        const contract_address = "0xDCDF4AB8feB42ecb3D2644F4100f77A59F0e78eF";
        const salt = "0x58af7b5043c35f089c99b49c810a9708a9e3adf6e16f94503cad160c62c64408";
        
        const domain_separator = domainSeparator(name, version, chain_id, contract_address, salt); 
        
//        console.log(domain_separator);
//        console.log( mintWithHash("0xF1F6720d4515934328896D37D356627522D97B49", 33333333333, 2))
        var typed_data = toTypedDataHash(domain_separator, mintWithHash("0xF1F6720d4515934328896D37D356627522D97B49", 33333333333, 121));
        console.log(typed_data);

        console.log( await web3.eth.sign(typed_data, account))
    
    } catch (e) {
        console.log(e.message)
    }
})()

function mintWithHash(to, tokenId, withdrawId)
{
    console.log("mint with hash type hash", web3.utils.keccak256(web3.utils.utf8ToHex("mintWithHash(address to,uint256 tokenId,uint256 withdrawId)")))
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32", "address", "uint256", "uint256"], [
            web3.utils.keccak256(web3.utils.utf8ToHex("mintWithHash(address to,uint256 tokenId,uint256 withdrawId)")),
            to,
            tokenId,
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