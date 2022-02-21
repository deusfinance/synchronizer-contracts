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
    uint256[5] public minPlatformFee; // minimum platform fee set by DEUS DAO
    uint256[5] public minTotalFee;  // minimum trading fee (total fee) set by DEUS DAO
    mapping(address => uint256[5]) public partnerFee; // partnerId => [stockFee, cryptoFee, forexFee, commodityFee, miscFee]
    address public platformFeeCollector; // platform multisig address
    uint256 public scale = 1e18; // used for math
    mapping(address => bool) public isPartner; // partnership of address

    constructor(address platformFeeCollector_, uint256[5] memory minPlatformFee_, uint256[5] memory minTotalFee_) {
        platformFeeCollector = platformFeeCollector_;
        minPlatformFee = minPlatformFee_;
        minTotalFee = minTotalFee_;
    }

    /// @notice become a partner of DEUS DAO
    /// @dev fees (18 decimals) are expressed as multipliers, e.g. 1% should be inserted as 0.01
    /// @param owner address of partner
    /// @param partnerStockFee fee charged for stocks (e.g. 0.1%)
    /// @param partnerCryptoFee fee charged for crypto (e.g. 0.1%)
    /// @param partnerForexFee fee charged for forex (e.g. 0.1%)
    /// @param partnerCommodityFee fee charged for commodities (e.g. 0.1%)
    /// @param partnerMiscFee fee charged for miscellaneous assets (e.g. 0.1%)
    function addPartner(
        address owner,
        uint256 partnerStockFee,
        uint256 partnerCryptoFee,
        uint256 partnerForexFee,
        uint256 partnerCommodityFee,
        uint256 partnerMiscFee
    ) external {
        require(!isPartner[owner], "PartnerManager: partner already exists");
        require(
            partnerStockFee + minPlatformFee[0] < scale &&
                partnerCryptoFee + minPlatformFee[1] < scale &&
                partnerForexFee + minPlatformFee[2] < scale &&
                partnerCommodityFee + minPlatformFee[3] < scale &&
                partnerMiscFee + minPlatformFee[4] < scale,
            "PartnerManager: the total fee can not be GTE 100%"
        );
        isPartner[owner] = true;
        partnerFee[owner] = [partnerStockFee, partnerCryptoFee, partnerForexFee, partnerCommodityFee, partnerMiscFee];
        emit PartnerAdded(owner, partnerFee[owner]);
    }
}

//Dar panah khoda
