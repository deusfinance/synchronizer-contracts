// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./Registrar.sol";

contract Conductor is Ownable {
	address public roleChecker;

    event Conduct(string _id, address short, address long);

	constructor(address roleChecker_) {
		roleChecker = roleChecker_;
	}

	function setRoleChecker(address roleChecker_) external onlyOwner {
		roleChecker = roleChecker_;
	}

	function adminConduct(
		string memory _id,
		string memory shortName,
		string memory shortSymbol,
		string memory longName,
		string memory longSymbol
	) external {
		Registrar short = new Registrar(roleChecker, shortName, shortSymbol);
		Registrar long = new Registrar(roleChecker, longName, longSymbol);
    
        emit Conduct(_id, address(short), address(long));
	}

}

//Dar panah khoda
