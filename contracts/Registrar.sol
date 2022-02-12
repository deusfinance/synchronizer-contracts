// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT

// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ==================== DEUS Registrar ======================
// ==========================================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IRoleChecker.sol";
import "./dERC20.sol";

contract Registrar is dERC20, Ownable {
    address public roleChecker;
    string public version;
    uint256 public registrarType;

    constructor(
        address roleChecker_,
        string memory name,
        string memory symbol,
        string memory version_,
        uint256 registrarType_
    ) dERC20(name, symbol) {
        roleChecker = roleChecker_;
        version = version_;
        registrarType = registrarType_;
    }

    modifier hasRole() {
        require(IRoleChecker(roleChecker).verify(msg.sender), "Registrar: role is not verified");
        _;
    }

    function rename(string memory name, string memory symbol) external hasRole {
        _name = name;
        _symbol = symbol;
    }

    function mint(address to, uint256 amount) external hasRole {
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external hasRole {
        _burn(from, amount);
    }
}

//Dar panah khoda
