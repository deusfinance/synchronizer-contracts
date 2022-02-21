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
// ==================== DEUS Synchronizer ===================
// ==========================================================
// DEUS Finance: https://github.com/deusfinance

// Primary Author(s)
// Vahid: https://github.com/vahid-dev

pragma solidity ^0.8.11;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "./interfaces/ISynchronizer.sol";
import "./interfaces/IDEIStablecoin.sol";
import "./interfaces/IRegistrar.sol";
import "./interfaces/IPartnerManager.sol";

/// @title Synchronizer
/// @author DEUS Finance
/// @notice DEUS router for trading Registrar contracts
contract Synchronizer is ISynchronizer, Ownable {
    using ECDSA for bytes32;

    // variables
    address public muonContract; // address of Muon verifier contract
    address public deiContract; // address of DEI token
    address public partnerManager; // address of partner manager contract
    uint256 public minimumRequiredSignatures; // minimum number of signatures required
    uint256 public scale = 1e18; // used for math
    mapping(address => uint256[5]) public feeCollector; // partnerId => cumulativeFee
    uint256 public virtualReserve; // used for collatDollarBalance()
    uint8 public appId; // Muon's app Id
    bool public useVirtualReserve; // to change collatDollarBalance() return amount

    constructor(
        address deiContract_,
        address muonContract_,
        address partnerManager_,
        uint256 minimumRequiredSignatures_,
        uint256 virtualReserve_,
        uint8 appId_
    ) {
        deiContract = deiContract_;
        muonContract = muonContract_;
        partnerManager = partnerManager_;
        minimumRequiredSignatures = minimumRequiredSignatures_;
        virtualReserve = virtualReserve_;
        appId = appId_;
    }

    /// @notice This function use pool feature to manage buyback and recollateralize on DEI minter pool
    /// @dev simulates the collateral in the contract
    /// @param collat_usd_price pool's collateral price (is 1e6) (decimal is 6)
    /// @return amount of collateral in the contract
    function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
        if (!useVirtualReserve) return 0;
        uint256 deiCollateralRatio = IDEIStablecoin(deiContract).global_collateral_ratio();
        return (virtualReserve * collat_usd_price * deiCollateralRatio) / 1e12;
    }

    /// @notice utility function used for generating trade signatures
    /// @return the chainId
    function getChainId() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice Calculate the fee percentage of registrar type for a specific partner
    /// @param partnerId address of partner
    /// @param registrar Registrar token address
    /// @return fee percentage (scale is 1e18)
    function getTotalFee(address partnerId, address registrar) public view returns (uint256 fee) {
        uint256 partnerFee = IPartnerManager(partnerManager).partnerFee(
            partnerId,
            IRegistrar(registrar).registrarType()
        );
        uint256 platformFee = IPartnerManager(partnerManager).minPlatformFee(IRegistrar(registrar).registrarType());
        uint256 minTotalFee = IPartnerManager(partnerManager).minTotalFee(IRegistrar(registrar).registrarType());
        if (partnerFee + platformFee <= minTotalFee) {
            fee = minTotalFee;
        }
        fee = partnerFee + platformFee;
    }

    /// @notice utility function for frontends
    /// @param partnerId address of partner
    /// @param amountOut amountOut to be received
    /// @param registrar Registrar token address
    /// @param price Registrar price
    /// @param action 0 is sell & 1 is buy
    /// @return amountIn required to receive the desired amountOut
    function getAmountIn(
        address partnerId,
        address registrar,
        uint256 amountOut,
        uint256 price,
        uint256 action
    ) public view returns (uint256 amountIn) {
        uint256 fee = getTotalFee(partnerId, registrar);
        if (action == 0) {
            // sell Registrar
            amountIn = (amountOut * price) / (scale - fee); // x = y * (price) * (1 / 1 - fee)
        } else {
            // buy Registrar
            amountIn = (amountOut * scale * scale) / (price * (scale - fee)); // x = y * / (price * (1 - fee))
        }
    }

    /// @notice utility function for frontends
    /// @param amountIn exact amount user wants to spend
    /// @param partnerId address of partner
    /// @param registrar Registrar token address
    /// @param price Registrar price
    /// @param action 0 is sell & 1 is buy
    /// @return amountOut to be received
    function getAmountOut(
        address partnerId,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 action
    ) public view returns (uint256 amountOut) {
        uint256 fee = getTotalFee(partnerId, registrar);
        if (action == 0) {
            // sell Registrar
            uint256 collateralAmount = (amountIn * price) / scale;
            uint256 feeAmount = (collateralAmount * fee) / scale;
            amountOut = collateralAmount - feeAmount;
        } else {
            // buy Registrar
            uint256 feeAmount = (amountIn * fee) / scale;
            uint256 collateralAmount = amountIn - feeAmount;
            amountOut = (collateralAmount * scale) / price;
        }
    }

    /// @notice buy a Registrar
    /// @dev SchnorrSign is a TSS structure
    /// @param partnerId partner address
    /// @param receipient receipient of the Registrar
    /// @param registrar Registrar token address
    /// @param amountIn DEI amount to spend (18 decimals)
    /// @param price registrar price according to Muon
    /// @param expireBlock last valid blockNumber before the signatures expire
    /// @param _reqId Muon request id
    /// @param sigs Muon TSS signatures
    function buyFor(
        address partnerId,
        address receipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 expireBlock,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external returns (uint256 registrarAmount) {
        require(amountIn > 0, "Synchronizer: INSUFFICIENT_INPUT_AMOUNT");
        require(IPartnerManager(partnerManager).isPartner(partnerId), "Synchronizer: INVALID_PARTNER_ID");
        require(sigs.length >= minimumRequiredSignatures, "Synchronizer: INSUFFICIENT_SIGNATURES");

        {
            bytes32 hash = keccak256(abi.encodePacked(registrar, price, expireBlock, uint256(1), getChainId(), appId));

            IMuonV02 muon = IMuonV02(muonContract);
            require(muon.verify(_reqId, uint256(hash), sigs), "Synchronizer: UNVERIFIED_SIGNATURES");
        }

        uint256 feeAmount = (amountIn * getTotalFee(partnerId, registrar)) / scale;
        uint256 collateralAmount = amountIn - feeAmount;

        feeCollector[partnerId][IRegistrar(registrar).registrarType()] += feeAmount;

        IDEIStablecoin(deiContract).pool_burn_from(msg.sender, amountIn);
        if (useVirtualReserve) virtualReserve -= amountIn;

        registrarAmount = (collateralAmount * scale) / price;
        IRegistrar(registrar).mint(receipient, registrarAmount);

        emit Buy(partnerId, receipient, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice sell a Registrar
    /// @dev SchnorrSign is a TSS structure
    /// @param partnerId partner address
    /// @param receipient receipient of the collateral
    /// @param registrar Registrar token address
    /// @param amountIn registrar amount to spend (18 decimals)
    /// @param price registrar price according to Muon
    /// @param expireBlock last valid blockNumber before the signatures expire
    /// @param _reqId Muon request id
    /// @param sigs Muon TSS signatures
    function sellFor(
        address partnerId,
        address receipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 expireBlock,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external returns (uint256 deiAmount) {
        require(amountIn > 0, "Synchronizer: INSUFFICIENT_INPUT_AMOUNT");
        require(IPartnerManager(partnerManager).isPartner(partnerId), "Synchronizer: INVALID_PARTNER_ID");
        require(sigs.length >= minimumRequiredSignatures, "Synchronizer: INSUFFICIENT_SIGNATURES");

        {
            bytes32 hash = keccak256(abi.encodePacked(registrar, price, expireBlock, uint256(0), getChainId(), appId));

            IMuonV02 muon = IMuonV02(muonContract);
            require(muon.verify(_reqId, uint256(hash), sigs), "Synchronizer: UNVERIFIED_SIGNATURES");
        }
        uint256 collateralAmount = (amountIn * price) / scale;
        uint256 feeAmount = (collateralAmount * getTotalFee(partnerId, registrar)) / scale;

        feeCollector[partnerId][IRegistrar(registrar).registrarType()] += feeAmount;

        IRegistrar(registrar).burn(msg.sender, amountIn);

        deiAmount = collateralAmount - feeAmount;
        IDEIStablecoin(deiContract).pool_mint(receipient, deiAmount);
        if (useVirtualReserve) virtualReserve += deiAmount;

        emit Sell(partnerId, receipient, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice withdraw accumulated trading fee
    /// @dev fee will be minted in DEI
    /// @param receipient receiver of fee
    /// @param registrarType type of registrar
    function withdrawFee(address receipient, uint256 registrarType) external {
        require(feeCollector[msg.sender][registrarType] > 0, "Synchronizer: INSUFFICIENT_FEE");

        uint256 partnerFee = IPartnerManager(partnerManager).partnerFee(msg.sender, registrarType);

        uint256 partnerFeeAmount = feeCollector[msg.sender][registrarType] * partnerFee / scale;
        uint256 platformFeeAmount = feeCollector[msg.sender][registrarType] - partnerFeeAmount;

        IDEIStablecoin(deiContract).pool_mint(receipient, partnerFeeAmount);
        IDEIStablecoin(deiContract).pool_mint(IPartnerManager(partnerManager).platformFeeCollector(), platformFeeAmount);
        feeCollector[msg.sender][registrarType] = 0;

        emit WithdrawFee(msg.sender, partnerFeeAmount, platformFeeAmount, registrarType);
    }

    /// @notice change the minimum required signatures for trading
    /// @param minimumRequiredSignatures_ number of required signatures
    function setMinimumRequiredSignatures(uint256 minimumRequiredSignatures_) external onlyOwner {
        emit SetMinimumRequiredSignatures(minimumRequiredSignatures, minimumRequiredSignatures_);
        minimumRequiredSignatures = minimumRequiredSignatures_;
    }

    /// @notice change Muon's app id
    /// @dev appIdd distinguishes us from other Muon apps
    /// @param appId_ Muon's app id
    function setAppId(uint8 appId_) external onlyOwner {
        emit SetAppId(appId, appId_);
        appId = appId_;
    }

    function setVirtualReserve(uint256 virtualReserve_) external onlyOwner {
        emit SetVirtualReserve(virtualReserve, virtualReserve_);
        virtualReserve = virtualReserve_;
    }

    function setMuonContract(address muonContract_) external onlyOwner {
        emit SetMuonContract(muonContract, muonContract_);
        muonContract = muonContract_;
    }

    /// @dev this affects buyback and recollateralize functions on the DEI minter pool
    function toggleUseVirtualReserve() external onlyOwner {
        useVirtualReserve = !useVirtualReserve;
        emit ToggleUseVirtualReserve(useVirtualReserve);
    }
}

//Dar panah khoda
