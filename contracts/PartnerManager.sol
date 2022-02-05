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
// ==================== Partner Manager ===================
// ========================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev
// M.R.M: https://github.com/mrmousavi78

pragma solidity ^0.8.11;

import "./interfaces/IPartnerManager.sol";

/// @title Partner Manager
/// @author deus.finance
/// @notice synchronizer's partner manager
contract PartnerManager is IPartnerManager {

    uint256[3] public platformFee; // platform trading fee
    mapping(address => uint256[3]) public partnerFee; // partner address => PartnerFee (e.g. 1e18 = 100%)
    address public platform; // platform multisig address
    uint256 public scale = 1e18; // used for math
    mapping(address => bool) public isPartner; // partnership of address

    constructor(address platform_, uint256[3] memory platformFee_) {
        platform = platform_;
        platformFee = platformFee_;
    }

    /// @notice to add partner
    /// @param owner address of partner multisig
    /// @param stockFee stock's fee (e.g. 1e18 = 100%)
    /// @param cryptoFee crypto's fee (e.g. 1e18 = 100%)
    /// @param forexFee forex's fee (e.g. 1e18 = 100%)
    function addPartner(
        address owner,
        uint256 stockFee,
        uint256 cryptoFee,
        uint256 forexFee
    ) external {
        require(!isPartner[owner], "PARTNER_MANAGER: partner has been set");
        require(stockFee < scale - platformFee[0] &&
                cryptoFee < scale - platformFee[1] &&
                forexFee < scale - platformFee[2],
                "PARTNER_MANAGER: the total fee can not be GTE 100%");
        isPartner[owner] = true;
        partnerFee[owner] = [stockFee, cryptoFee, forexFee];
        emit PartnerAdded(owner, partnerFee[owner]);
    }
}
//Dar panah khoda
