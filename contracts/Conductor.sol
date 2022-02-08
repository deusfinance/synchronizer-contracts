// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IConductor.sol";
import "./Registrar.sol";

contract Conductor is IConductor, Ownable {
	address public roleChecker;

	constructor(address roleChecker_) {
		roleChecker = roleChecker_;
	}

	function setRoleChecker(address roleChecker_) external onlyOwner {
		roleChecker = roleChecker_;
	}

	function conduct(
		string memory _id,
		string memory shortName,
		string memory shortSymbol,
		string memory longName,
		string memory longSymbol,
		string memory version,
		uint256 registrarType
	) external returns (address, address) {
		Registrar short = new Registrar(roleChecker, shortName, shortSymbol, version, registrarType);
		Registrar long = new Registrar(roleChecker, longName, longSymbol, version, registrarType);
        emit Conducted(_id, address(short), address(long));

		return (address(short), address(long));
	}
}

//Dar panah khoda
