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
// DEUS Finance: https://github.com/DeusFinance

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
/// @author deus.finance
/// @notice deus ecosystem synthetics token trading contract
contract Synchronizer is ISynchronizer, Ownable {
    using ECDSA for bytes32;

    // variables
    address public muonContract;  // address of muon verifier contract
    address public deiContract;  // address of dei token
    address public partnerManager;  // address of partner manager contract
    uint256 public minimumRequiredSignature;  // number of signatures that required
    uint256 public scale = 1e18;  // used for math
    mapping(address => uint256) public trades;  // partner address => trading volume
    uint256 public virtualReserve;  // used for collatDollarBalance()
    uint8 public appID;  // muon's app id
    bool public useVirtualReserve;  // to change collatDollarBalance() return amount

    constructor (
        address deiContract_,
        address muonContract_,
        address partnerManager_,
        uint256 minimumRequiredSignature_,
        uint256 virtualReserve_,
        uint8 appID_

    ) {
        deiContract = deiContract_;
        muonContract = muonContract_;
        partnerManager = partnerManager_;
        minimumRequiredSignature = minimumRequiredSignature_;
        virtualReserve = virtualReserve_;
        appID = appID_;
    }

    /// @notice This function use pool feature to manage buyback and recollateralize on DEI minter pool
    /// @dev simulates the collateral in the contract
    /// @param collat_usd_price pool's collateral price (is 1e6) (decimal is 6)
    /// @return amount of collateral in the contract
    function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
        if (!useVirtualReserve) return 0;
        uint256 collateralRatio = IDEIStablecoin(deiContract).global_collateral_ratio();
        return (virtualReserve * collat_usd_price * collateralRatio) / 1e12;
    }

    /// @notice used for trade signatures
    /// @return number of chainID
    function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

    /// @notice view functions for frontend
    /// @param amountOut amount that you want at the end
    /// @param partnerID address of partner
    /// @param registrar synthetic token address
    /// @param price synthetic price
    /// @param action 0 is sell & 1 is buy
    /// @return amountIn for trading
    function getAmountIn(address partnerID, address registrar, uint256 amountOut, uint256 price, uint256 action) public view returns (uint256 amountIn) {
        uint256 fee = IPartnerManager(partnerManager).partnerTradingFee(partnerID, IRegistrar(registrar).registrarType());
        if (action == 0) {  // sell synthetic token
            amountIn = amountOut * price / scale - fee;  // x = y * (price) * (1 / 1 - fee)
        } else {  // buy synthetic token
            amountIn = amountOut * scale * scale / (price * (scale - fee));  // x = y * / (price * (1 - fee))
        }
    }

    /// @notice view functions for frontend
    /// @param amountIn amount that you want sell
    /// @param partnerID address of partner
    /// @param registrar synthetic token address
    /// @param price synthetic price
    /// @param action 0 is sell & 1 is buy
    /// @return amountOut for trading
    function getAmountOut(address partnerID, address registrar, uint256 amountIn, uint256 price, uint256 action) public view returns (uint256 amountOut) {
        uint256 fee = IPartnerManager(partnerManager).partnerTradingFee(partnerID, IRegistrar(registrar).registrarType());
        if (action == 0) {  // sell synthetic token +
            uint256 collateralAmount = amountIn * price / scale;
            uint256 feeAmount = collateralAmount * fee / scale;
            amountOut = collateralAmount - feeAmount;
        } else {  // buy synthetic token
            uint256 feeAmount = amountIn * fee / scale;
            uint256 collateralAmount = amountIn - feeAmount;
            amountOut = collateralAmount * scale / price;
        }
    }

    /// @notice to sell the synthetic tokens
    /// @dev SchnorrSign is a TSS structure
    /// @param partnerID partner address
    /// @param _user collateral will be send to the _user
    /// @param registrar synthetic token address
    /// @param amountIn synthetic token amount (decimal is 18)
    /// @param expireBlock signature expire time
    /// @param price synthetic token price
    /// @param _reqId muon request id
    /// @param sigs muon network's TSS signatures
    function sellFor(
        address partnerID,
        address _user,
        address registrar,
        uint256 amountIn,
        uint256 expireBlock,
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    )
        external
    {
        require(amountIn > 0, "SYNCHRONIZER: amount should be bigger than 0");
        require(IPartnerManager(partnerManager).isPartner(partnerID), "SYNCHRONIZER: invalid partnerID");
        require(
            sigs.length >= minimumRequiredSignature,
            "SYNCHRONIZER: insufficient number of signatures"
        );

        uint256 fee = IPartnerManager(partnerManager).partnerTradingFee(partnerID, IRegistrar(registrar).registrarType());

        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    registrar, 
                    price, 
                    fee, 
                    expireBlock, 
                    uint256(0),
                    getChainID(),
                    appID
                )
            );

            IMuonV02 muon = IMuonV02(muonContract);
            require(
                muon.verify(_reqId, uint256(hash), sigs),
                "SYNCHRONIZER: not verified"
            );
        }
        uint256 collateralAmount = amountIn * price / scale;
        uint256 feeAmount = collateralAmount * fee / scale;

        trades[partnerID] += feeAmount;

        IRegistrar(registrar).burn(msg.sender, amountIn);

        uint256 deiAmount = collateralAmount - feeAmount;
        IDEIStablecoin(deiContract).pool_mint(_user, deiAmount);
        if (useVirtualReserve) virtualReserve += deiAmount;

        emit Sell(partnerID, _user, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice to buy the synthetic tokens
    /// @dev SchnorrSign is a TSS structure
    /// @param partnerID partner address
    /// @param _user synthetic token will be send to the _user
    /// @param registrar synthetic token address
    /// @param amountIn dei token amount (decimal is 18)
    /// @param expireBlock signature expire time
    /// @param price synthetic token price
    /// @param _reqId muon request id
    /// @param sigs muon network's TSS signatures
    function buyFor(
        address partnerID,
        address _user,
        address registrar,
        uint256 amountIn,
        uint256 expireBlock,
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    )
        external
    {
        require(amountIn > 0, "SYNCHRONIZER: amount should be bigger than 0");
        require(IPartnerManager(partnerManager).isPartner(partnerID), "SYNCHRONIZER: invalid partnerID");
        require(
            sigs.length >= minimumRequiredSignature,
            "SYNCHRONIZER: insufficient number of signatures"
        );

        uint256 fee = IPartnerManager(partnerManager).partnerTradingFee(partnerID, IRegistrar(registrar).registrarType());

        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    registrar, 
                    price, 
                    fee, 
                    expireBlock, 
                    uint256(1),
                    getChainID(),
                    appID
                )
            );

            IMuonV02 muon = IMuonV02(muonContract);
            require(
                muon.verify(_reqId, uint256(hash), sigs),
                "SYNCHRONIZER: not verified"
            );
        }

        uint256 feeAmount = amountIn * fee / scale;
        uint256 collateralAmount = amountIn - feeAmount;

        trades[partnerID] += feeAmount;

        IDEIStablecoin(deiContract).pool_burn_from(msg.sender, amountIn);
        if (useVirtualReserve) virtualReserve -= amountIn;

        uint256 registrarAmount = collateralAmount * scale / price;
        IRegistrar(registrar).mint(_user, registrarAmount);

        emit Buy(partnerID, _user, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice withdraw accumulated trading fee
    /// @dev fee will be minted in DEI
    function withdrawFee() external {
        require(trades[msg.sender] > 0, "SYNCHRONIZER: fee is zero");
        uint256 partnerFee = trades[msg.sender] * IPartnerManager(partnerManager).partnerShare(msg.sender) / scale;
        uint256 platformFee = trades[msg.sender] - partnerFee;
        IDEIStablecoin(deiContract).pool_mint(msg.sender, partnerFee);
        IDEIStablecoin(deiContract).pool_mint(IPartnerManager(partnerManager).platform(), platformFee);
        trades[msg.sender] = 0;
        emit WithdrawFee(msg.sender, partnerFee, platformFee);
    }

    /// @notice changes minimum required signatures in trading functions by DAO
    /// @param minimumRequiredSignature_ number of required signatures
    function setMinimumRequiredSignature(uint256 minimumRequiredSignature_) external onlyOwner {
        emit MinimumRequiredSignatureSet(minimumRequiredSignature, minimumRequiredSignature_);
        minimumRequiredSignature = minimumRequiredSignature_;
    }

    /// @notice changes muon's app id by DAO
    /// @dev each app becomes different from others by app id
    /// @param appID_ muon's app id
    function setAppId(uint8 appID_) external onlyOwner {
        emit AppIdSet(appID, appID_);
        appID = appID_;
    }

    function setVirtualReserve(uint256 virtualReserve_) external onlyOwner {
        emit VirtualReserveSet(virtualReserve, virtualReserve_);
        virtualReserve = virtualReserve_;
    }

    function setMuonContract(address muonContract_) external onlyOwner {
        emit MuonContractSet(muonContract, muonContract_);
        muonContract = muonContract_;
    }
    
    /// @dev it affects buyback and recollateralize functions on DEI minter pool 
    function toggleUseVirtualReserve() external onlyOwner {
        useVirtualReserve = !useVirtualReserve;
        emit UseVirtualReserveToggled(useVirtualReserve);
    }
}

//Dar panah khoda
