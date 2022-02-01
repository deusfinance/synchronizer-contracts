//Be name khoda
//Bime Abolfazl

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRoleChecker.sol";

contract RoleChecker is IRoleChecker, Ownable {
    mapping(address => bool) private hasRole;

    constructor () {}

    function verify(address caller) public view returns (bool) {
        return hasRole[caller];
    }

    function grant(address user) external onlyOwner {
        hasRole[user] = true;
    }

    function revoke(address user) external onlyOwner {
        delete hasRole[user];
    }
}
//Dar panah khoda
