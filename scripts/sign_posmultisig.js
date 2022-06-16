// Right click on the script name and hit "Run" to execute
(async () => {
    try {
        console.log('Running PoSMultisigAdmin sign test...')
        const account = (await web3.eth.getAccounts())[0];

//        console.log("address", account)

        const name = "PoSMultisigAdmin";
        const version = "1.0";
        const chain_id = await web3.eth.getChainId();
        const contract_address = "0x4ba476570e5a2ca5547d0be904a26a91355663b0";
        const salt = "0x0caaadd5fd4d8a10894f330ae16c94ab15949942ce2610697319e90402db033f";


        const domain_separator = domainSeparator(name, version, chain_id, contract_address, salt);      
//        console.log("domain_separator", domain_separator);

        var to = "0xBb7403aAF82342A0d987A8603aAf881136B5D125";
        var value = "1";
        var data = "0x";
        var transaction_id = 2;
        var sender = "0xF1F6720d4515934328896D37D356627522D97B49";

        console.log("data hash", executeTransactionHash(to, value, data, transaction_id, sender));

        var typed_data = toTypedDataHash(domain_separator, executeTransactionHash(to, value, data, transaction_id, sender));
        console.log("typed_data", typed_data);

        console.log("signature", await web3.eth.sign(typed_data, account))
    
    } catch (e) {
        console.log(e.message)
    }
})()

function executeTransactionHash(to, value, data, transaction_id, sender)
{
//    console.log("executeTransaction type hash", web3.utils.keccak256(web3.utils.utf8ToHex("executeTransaction(address to,uint256 value,bytes data,uint256 transaction_id,address sender)")))
    return web3.utils.keccak256(web3.eth.abi.encodeParameters(["bytes32", "address", "uint256", "bytes32", "uint256", "address"], [
            web3.utils.keccak256(web3.utils.utf8ToHex("executeTransaction(address to,uint256 value,bytes data,uint256 transaction_id,address sender)")),
            to,
            value,
            (data != "0x" ? web3.utils.keccak256(data) : "0xc5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470"),
            transaction_id,
            sender
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