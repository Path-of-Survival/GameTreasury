// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "../cryptography/EIP712.sol";

contract PoSMultisigAdmin is EIP712
{
    mapping (uint => bool) private transactions;
    mapping (address => bool) private admins;
    uint private admins_count = 0;
    uint private threshold = 0;

    bytes32 constant private EXECUTE_TRANSACTION_TYPE_HASH = 0x4f1487070572b50e8a5bc21624e1d55dea0c6bf8f5c1b1bfdb278617680daff4;

    event AdminAdded(address _admin);
    event AdminRemoved(address _admin);
    event ThresholdChanged(uint _threshold);

    constructor(address[] memory _admins, uint _threshold, bytes32 eip712_salt) EIP712("PoSMultisigAdmin", "1.0", eip712_salt)
    {
        require(_admins.length > 0 && _threshold > 0 && _threshold <= _admins.length);
        admins_count = _admins.length;
        threshold = _threshold;
        for (uint i=0; i<_admins.length; i++) 
        {
            require(_admins[i] != address(0) && _admins[i] != address(this) && admins[_admins[i]] == false);
            admins[_admins[i]] = true;
            emit AdminAdded(_admins[i]);
        }
        emit ThresholdChanged(threshold);
    }

    modifier selfAuthorized() 
    {
        require(msg.sender == address(this), "not selfAuthorized");
        _;
    }

    function changeThreshold(uint _threshold) public selfAuthorized 
    {
        require(_threshold <= admins_count && _threshold > 0, "_threshold is out of range");
        threshold = _threshold;
        emit ThresholdChanged(threshold);
    }

    function addAdmin(address _admin, uint _threshold) public selfAuthorized
    {
        require(_admin != address(0) && _admin != address(this) && admins[_admin] == false, "Invalid admin address");
        admins[_admin] = true;
        admins_count++;
        emit AdminAdded(_admin);
    
        if (_threshold != 0 && _threshold != threshold)
            changeThreshold(_threshold);       
    }

    function removeAdmin(address _admin, uint _threshold) public selfAuthorized
    {
        require((_threshold == 0 && threshold <= admins_count - 1) || (_threshold != 0 && _threshold <= admins_count - 1), "threshold is too high" );
        require(admins[_admin] == true , "Invalid admin address");
        admins[_admin] = false;
        admins_count--;
        emit AdminRemoved(_admin);

        if (_threshold != 0 && _threshold != threshold)
            changeThreshold(_threshold); 
    }

    function txHash(address to, uint value, bytes calldata data, uint transaction_id, address sender) public view returns(bytes32, bytes32)
    {
        bytes32 data_hash = keccak256(abi.encode(EXECUTE_TRANSACTION_TYPE_HASH, to, value, keccak256(data), transaction_id, sender));
        return (data_hash, EIP712._domainSeparatorV4());
    }
    
    function executeTransaction(address to, uint value, bytes calldata data, uint transaction_id, bytes calldata signatures) public payable returns(bool)
    {
        require(value == msg.value, "Wrong msg.value");
        require(transactions[transaction_id] == false, "Invalid transaction_id");
        require(signatures.length >= threshold*65 && signatures.length % 65 == 0, "Invalid signatures format");
        bytes32 data_hash = keccak256(abi.encode(EXECUTE_TRANSACTION_TYPE_HASH, to, value, keccak256(data), transaction_id, msg.sender));
        address last_address = address(0);
        for(uint i=0; i<threshold; i++)
        {
            address curr_address = EIP712.recoverSigner(data_hash, signatures[i*65:(i+1)*65]);
            require(curr_address != address(0) && admins[curr_address] == true && curr_address > last_address, "Invalid signature");
            last_address = curr_address;
        }

        (bool success, ) = to.call{value:value}(data);
        transactions[transaction_id] = true;
        
        return success;
    }

    function isAdmin(address _address) public view returns(bool)
    {
        return admins[_address];
    }

    function getAdminsCount() public view returns (uint)
    {
        return admins_count;
    }

    function getThreshold() public view returns (uint)
    {
        return threshold;
    }
}