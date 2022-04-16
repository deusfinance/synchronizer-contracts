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

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "./interfaces/IPartnerManager.sol";

/// @title Partner Manager
/// @author DEUS Finance
/// @notice Partner manager for the Synchronizer
contract PartnerManager is IPartnerManager, Ownable {
    uint256 public scale = 1e18; // used for math
    address public platformFeeCollector; // platform multisig address
    uint256[] public minPlatformFee; // minimum platform fee set by DEUS DAO
    uint256[] public minTotalFee; // minimum trading fee (total fee) set by DEUS DAO
    mapping(address => uint256[]) public partnerFee; // partnerId => [stockFee, cryptoFee, forexFee, commodityFee, miscFee, ...]
    mapping(address => bool) public isPartner; // partnership of address
    mapping(address => int256) public maxCap; // maximum cap of open positions volume

    constructor(
        address owner,
        address platformFeeCollector_,
        uint256[] memory minPlatformFee_,
        uint256[] memory minTotalFee_
    ) {
        platformFeeCollector = platformFeeCollector_;
        minPlatformFee = minPlatformFee_;
        minTotalFee = minTotalFee_;
        transferOwnership(owner);
    }

    /// @notice become a partner of DEUS DAO
    /// @dev fees (18 decimals) are expressed as multipliers, e.g. 1% should be inserted as 0.01
    /// @param registrarType list of registrar types
    /// @param partnerFee_ list of fee amounts of registrars
    function addRegistrarFee(uint256[] memory registrarType, uint256[] memory partnerFee_) external {
        isPartner[msg.sender] = true;
        partnerFee[msg.sender] = new uint256[](registrarType.length);
        for (uint256 i = 0; i < registrarType.length; i++) {
            require(
                partnerFee_[registrarType[i]] + minPlatformFee[registrarType[i]] < scale,
                "PartnerManager: INVALID_TOTAL_FEE"
            );
            partnerFee[msg.sender][registrarType[i]] = partnerFee_[registrarType[i]];
        }

        emit RegistrarFeeAdded(msg.sender, registrarType, partnerFee_);
    }

    /// @notice add new registrars to the platform
    /// @dev fees (18 decimals) are expressed as multipliers, e.g. 1% should be inserted as 0.01
    /// @param registrarType list of registrar types
    /// @param minPlatformFee_ list of minimum platform fee
    /// @param minTotalFee_ list of minimum trading fee
    function addPlatformFee(
        uint256[] memory registrarType,
        uint256[] memory minPlatformFee_,
        uint256[] memory minTotalFee_
    ) external onlyOwner {
        minPlatformFee = new uint256[](registrarType.length);
        minTotalFee = new uint256[](registrarType.length);
        for (uint256 i = 0; i < registrarType.length; i++) {
            minPlatformFee[registrarType[i]] = minPlatformFee_[registrarType[i]];
            minTotalFee[registrarType[i]] = minTotalFee_[registrarType[i]];
        }

        emit PlatformFeeAdded(registrarType, minPlatformFee_, minTotalFee_);
    }

    /// @notice sets maximum cap for partner
    /// @param partnerId Address of partner
    /// @param cap Maximum cap of partner
    /// @param isNegative Is true when you want to set negative cap
    function setCap(
        address partnerId,
        int256 cap,
        bool isNegative
    ) external onlyOwner {
        if (!isNegative) {
            require(cap >= 0, "ParnerManager: INVALID_CAP");
        }
        maxCap[partnerId] = cap;
        emit SetCap(partnerId, cap);
    }
}

//Dar panah khoda
