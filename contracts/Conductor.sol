// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./Registrar.sol";

contract Conductor is AccessControl {
    mapping(string => address) public registrars;

	address public synchronizer;
	address public admin;
	address public liquidator;

    event Conduct(string _id, address short, address long);

	constructor(address _synchronizer, address _admin, address _liquidator) {
		synchronizer = _synchronizer;
		admin = _admin;	
		liquidator = _liquidator;
		_setupRole(DEFAULT_ADMIN_ROLE, _admin);
	}

	function setAddresses(address _synchronizer, address _admin, address _liquidator) public{
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
		liquidator = _liquidator;
		synchronizer = _synchronizer;
		admin = _admin;	
	}

	function adminConduct(
		string memory _id,
		string memory shortName,
		string memory shortSymbol,
		string memory longName,
		string memory longSymbol
	)external{
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
		Registrar short = new Registrar(admin, synchronizer, liquidator, shortName, shortSymbol);
		Registrar long = new Registrar(admin, synchronizer, liquidator, longName, longSymbol);

        registrars[_id] = address(long);
    
        emit conduct(_id, address(short), address(long));
	}

}

//Dar panah khoda
