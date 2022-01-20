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
		string memory longSymbol,
		string memory version
	) external {
		Registrar short = new Registrar(roleChecker, shortName, shortSymbol, version);
		Registrar long = new Registrar(roleChecker, longName, longSymbol, version);
    
        emit Conduct(_id, address(short), address(long));
	}

}

//Dar panah khoda
