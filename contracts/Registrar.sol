//Be name khoda
//Bime Abolfazl

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRoleChecker.sol";
import "./dERC20.sol";

contract Registrar is dERC20, Ownable {

	address public roleChecker;

	constructor(address roleChecker_, string memory name, string memory symbol) dERC20(name, symbol) {
		roleChecker = roleChecker_;
	}

	modifier hasRole(address user) {
		require(IRoleChecker(roleChecker).verify(user), "Caller doesnt have role");
		_;
	}

	function rename(string memory name, string memory symbol) external hasRole(msg.sender) {
		_name = name;
		_symbol = symbol;
	}

	function mint(address to, uint256 amount) external hasRole(msg.sender) {
        _mint(to, amount);
    }

	function burn(address from, uint256 amount) external hasRole(msg.sender) {
        _burn(from, amount);
    }

}
//Dar panah khoda
