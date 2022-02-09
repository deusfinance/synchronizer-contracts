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
// ================== DEUS Partner Manager ================
// ========================================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev
// M.R.M: https://github.com/mrmousavi78

pragma solidity ^0.8.11;

import "./interfaces/IPartnerManager.sol";

/// @title Partner Manager
/// @author DEUS Finance
/// @notice Partner manager for the Synchronizer
contract PartnerManager is IPartnerManager {
    uint256[3] public platformFee; // trading fee set by DEUS DAO
    mapping(address => uint256[3]) public partnerFee; // partnerId => PartnerFee
    address public platform; // platform multisig address
    uint256 public scale = 1e18; // used for math
    mapping(address => bool) public isPartner; // partnership of address

    constructor(address platform_, uint256[3] memory platformFee_) {
        platform = platform_;
        platformFee = platformFee_;
    }

    /// @notice become a partner of DEUS DAO
    /// @param owner address of partner
    /// @param stockFee fee charged for stocks (e.g. 0.1%)
    /// @param cryptoFee fee charged for crypto (e.g. 0.3%)
    /// @param forexFee fee charged for forex (e.g. 0.1%)
    function addPartner(
        address owner,
        uint256 stockFee,
        uint256 cryptoFee,
        uint256 forexFee
    ) external {
        require(!isPartner[owner], "PartnerManager: partner already exists");
        require(
            stockFee < scale - platformFee[0] &&
                cryptoFee < scale - platformFee[1] &&
                forexFee < scale - platformFee[2],
            "PartnerManager: the total fee can not be GTE 100%"
        );
        isPartner[owner] = true;
        partnerFee[owner] = [stockFee, cryptoFee, forexFee];
        emit PartnerAdded(owner, partnerFee[owner]);
    }
}

//Dar panah khoda
