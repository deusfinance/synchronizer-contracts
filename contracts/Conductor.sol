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
// ================== DEUS Conductor ======================
// ========================================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IConductor.sol";
import "./interfaces/IRegistrar.sol";
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

    function liquidate(
        address registrar,
        string memory liquidatedName,
        string memory liquidatedSymbol,
        string memory version
    ) external onlyOwner {
        string memory name = IRegistrar(registrar).name();
        string memory symbol = IRegistrar(registrar).symbol();
        uint256 registrarType = IRegistrar(registrar).registrarType();
        IRegistrar(registrar).rename(liquidatedName, liquidatedSymbol);
        Registrar newRegistrar = new Registrar(roleChecker, name, symbol, version, registrarType);
        emit Liquidated(registrar, address(newRegistrar));
    }
}

//Dar panah khoda
