// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";

contract AdminPrivileges is Ownable
{
    mapping (address => bool) private _admins; 
    function isAdmin(address _address) public view returns(bool)
    {
        return _admins[_address];
    }

    modifier onlyAdmins() 
    {
        require(_admins[_msgSender()] == true, "AdminPrivileges: the caller does not have permissions");
        _;
    }

    function addAdmin(address admin) external onlyOwner
    {
        _admins[admin] = true;
    }

    function removeAdmin(address admin) external onlyOwner
    {
        _admins[admin] = false;
    }
}