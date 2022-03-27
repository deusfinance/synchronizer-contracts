// Be name Khoda
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

pragma solidity 0.8.13;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/cryptography/ECDSA.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "./interfaces/ISynchronizer.sol";
import "./interfaces/IMintHelper.sol";
import "./interfaces/IRegistrar.sol";
import "./interfaces/IPartnerManager.sol";

/// @title Synchronizer
/// @author DEUS Finance
/// @notice DEUS router for trading Registrar contracts
contract Synchronizer is ISynchronizer, ReentrancyGuard, Ownable {
    using ECDSA for bytes32;

    uint8 public appId; // Muon's app Id
    string public version = "v1.2.0";
    address public muonContract; // Address of Muon verifier contract
    address public deiContract = 0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3; // address of DEI token
    address public mintHelper; // Address of mint helper contract
    address public partnerManager; // Address of partner manager contract
    uint256 public minimumRequiredSignatures; // Minimum number of signatures required
    uint256 public scale = 1e18; // Used for math
    uint256 public expireTime; // Valid time of muon signatures
    uint256 public delayTimestamp; // Time to wait before being able to collect()
    mapping(address => int256) public cap; // partnerId => openPositionsVolume
    mapping(address => uint256) public lastTrade; // Address => last trade timestamp
    mapping(address => uint256[]) public feeCollector; // partnerId => cumulativeFee
    mapping(address => address[]) public tokens; // Address => list of collectibale tokens
    mapping(address => mapping(address => uint256)) public balance; // Balance of collectible tokens

    constructor(
        address mintHelper_,
        address muonContract_,
        address partnerManager_,
        uint256 minimumRequiredSignatures_,
        uint256 expireTime_,
        uint256 delayTimestamp_,
        uint8 appId_
    ) ReentrancyGuard() {
        mintHelper = mintHelper_;
        muonContract = muonContract_;
        partnerManager = partnerManager_;
        minimumRequiredSignatures = minimumRequiredSignatures_;
        expireTime = expireTime_;
        delayTimestamp = delayTimestamp_;
        appId = appId_;
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
        } else {
            fee = partnerFee + platformFee;
        }
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
    /// @param recipient recipient of the Registrar
    /// @param registrar Registrar token address
    /// @param amountIn DEI amount to spend (18 decimals)
    /// @param price registrar price according to Muon
    /// @param timestamp timestamp for signatures expiration
    /// @param _reqId Muon request id
    /// @param sigs Muon TSS signatures
    function buyFor(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 timestamp,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external nonReentrant() returns (uint256 registrarAmount) {
        require(amountIn > 0, "Synchronizer: INSUFFICIENT_INPUT_AMOUNT");
        require(IPartnerManager(partnerManager).isPartner(partnerId), "Synchronizer: INVALID_PARTNER_ID");
        require(sigs.length >= minimumRequiredSignatures, "Synchronizer: INSUFFICIENT_SIGNATURES");
        require(timestamp + expireTime > block.timestamp, "Synchronizer: EXPIRED_SIGNATURE");
        require(int256(amountIn) > 0, "Synchronizer: INVALID_AMOUNTIN");
        require(
            int256(amountIn) + cap[partnerId] <= IPartnerManager(partnerManager).maxCap(partnerId),
            "Synchronizer: MAX_CAP"
        );

        {
            bytes32 hash = keccak256(abi.encodePacked(registrar, price, uint256(1), getChainId(), appId, timestamp));

            IMuonV02 muon = IMuonV02(muonContract);
            require(muon.verify(_reqId, uint256(hash), sigs), "Synchronizer: UNVERIFIED_SIGNATURES");
        }

        uint256 feeAmount = (amountIn * getTotalFee(partnerId, registrar)) / scale;
        uint256 collateralAmount = amountIn - feeAmount;

        feeCollector[partnerId][IRegistrar(registrar).registrarType()] += feeAmount;

        IMintHelper(mintHelper).burnFrom(msg.sender, amountIn);

        cap[partnerId] += int256(amountIn);

        registrarAmount = (collateralAmount * scale) / price;

        IRegistrar(registrar).mint(address(this), registrarAmount);

        {
            lastTrade[recipient] = block.timestamp;
            balance[recipient][registrar] += registrarAmount;
            tokens[recipient].push(registrar);
        }

        emit Buy(partnerId, recipient, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice sell a Registrar
    /// @dev SchnorrSign is a TSS structure
    /// @param partnerId partner address
    /// @param recipient recipient of the collateral
    /// @param registrar Registrar token address
    /// @param amountIn registrar amount to spend (18 decimals)
    /// @param price registrar price according to Muon
    /// @param timestamp timestamp for signatures expiration
    /// @param _reqId Muon request id
    /// @param sigs Muon TSS signatures
    function sellFor(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 timestamp,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external nonReentrant() returns (uint256 deiAmount) {
        require(amountIn > 0, "Synchronizer: INSUFFICIENT_INPUT_AMOUNT");
        require(IPartnerManager(partnerManager).isPartner(partnerId), "Synchronizer: INVALID_PARTNER_ID");
        require(sigs.length >= minimumRequiredSignatures, "Synchronizer: INSUFFICIENT_SIGNATURES");
        require(timestamp + expireTime > block.timestamp, "Synchronizer: EXPIRED_SIGNATURE");

        {
            bytes32 hash = keccak256(abi.encodePacked(registrar, price, uint256(0), getChainId(), appId, timestamp));

            IMuonV02 muon = IMuonV02(muonContract);
            require(muon.verify(_reqId, uint256(hash), sigs), "Synchronizer: UNVERIFIED_SIGNATURES");
        }
        uint256 collateralAmount = (amountIn * price) / scale;

        require(int256(collateralAmount) > 0, "Synchronizer: INVALID_COLLATERAL_AMOUNT");

        uint256 feeAmount = (collateralAmount * getTotalFee(partnerId, registrar)) / scale;

        feeCollector[partnerId][IRegistrar(registrar).registrarType()] += feeAmount;

        IRegistrar(registrar).burn(msg.sender, amountIn);

        deiAmount = collateralAmount - feeAmount;
        IMintHelper(mintHelper).mint(address(this), deiAmount);

        {
            lastTrade[recipient] = block.timestamp;
            balance[recipient][deiContract] += deiAmount;
            tokens[recipient].push(deiContract);
        }

        cap[partnerId] -= int256(collateralAmount);

        emit Sell(partnerId, recipient, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice collects the tokens
    /// @param recipient recipient of the tokens
    function collect(address recipient) external nonReentrant() {
        require(lastTrade[msg.sender] + delayTimestamp < block.timestamp, "Synchronizer: WAITING_TIME");

        uint256 cnt = tokens[msg.sender].length;

        for (uint256 i = 0; i < cnt; i++) {
            address token = tokens[msg.sender][i];
            uint256 amount = balance[msg.sender][token];
            if (amount > 0) {
                balance[msg.sender][token] = 0;
                IERC20(token).transfer(recipient, amount);
            }
        }
        delete tokens[msg.sender];
    }

    /// @notice withdraw accumulated trading fee
    /// @dev fee will be minted in DEI
    /// @param recipient receiver of fee
    /// @param registrarType type of registrar
    function withdrawFee(address recipient, uint256 registrarType) external {
        require(feeCollector[msg.sender][registrarType] > 0, "Synchronizer: INSUFFICIENT_FEE");

        uint256 partnerFee = IPartnerManager(partnerManager).partnerFee(msg.sender, registrarType);

        uint256 partnerFeeAmount = (feeCollector[msg.sender][registrarType] * partnerFee) / scale;
        uint256 platformFeeAmount = feeCollector[msg.sender][registrarType] - partnerFeeAmount;

        IMintHelper(mintHelper).mint(recipient, partnerFeeAmount);
        IMintHelper(mintHelper).mint(IPartnerManager(partnerManager).platformFeeCollector(), platformFeeAmount);

        feeCollector[msg.sender][registrarType] = 0;

        emit WithdrawFee(msg.sender, partnerFeeAmount, platformFeeAmount, registrarType);
    }

    /// @notice changes the minimum required signatures for trading
    /// @param minimumRequiredSignatures_ number of required signatures
    function setMinimumRequiredSignatures(uint256 minimumRequiredSignatures_) external onlyOwner {
        emit SetMinimumRequiredSignatures(minimumRequiredSignatures, minimumRequiredSignatures_);
        minimumRequiredSignatures = minimumRequiredSignatures_;
    }

    /// @notice changes Muon's app id
    /// @dev appIdd distinguishes us from other Muon apps
    /// @param appId_ Muon's app id
    function setAppId(uint8 appId_) external onlyOwner {
        emit SetAppId(appId, appId_);
        appId = appId_;
    }

    /// @notice changes Muon's verifier contract
    /// @param muonContract_ address of muon contract
    function setMuonContract(address muonContract_) external onlyOwner {
        emit SetMuonContract(muonContract, muonContract_);
        muonContract = muonContract_;
    }

    /// @notice changes expire time
    /// @param expireTime_ new exipre time
    function setExpireTime(uint256 expireTime_) external onlyOwner {
        emit SetExpireTime(expireTime, expireTime_);
        expireTime = expireTime_;
    }

    function setDelayTimestamp(uint256 delayTimestamp_) external onlyOwner {
        emit SetDelayTimestamp(delayTimestamp, delayTimestamp_);
        delayTimestamp = delayTimestamp_;
    }
}

//Dar panah khoda
