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


/// @title Synchronizer
/// @author deus.finance
/// @notice deus ecosystem synthetics token trading contract
contract Synchronizer is ISynchronizer, Ownable {
    using ECDSA for bytes32;

    // variables
    address public muonContract;  // address of muon verifier contract
    address public deiContract;  // address of dei token
    address public spiritSwapDao;
    address public deusDao;
    uint256 public minimumRequiredSignature;  // number of signatures that required
    uint256 public scale = 1e18;  // used for math
    uint256 public spiritSwapDaoShare = 2e18;  // spirit swap dao share
    uint256 public deusDaoShare = 1e18;  // deus dao share
    uint256 public withdrawableFeeAmount;  // trading fee amount
    uint256 public virtualReserve;
    uint8 public APP_ID;  // muon's app id
    bool public useVirtualReserve;

    event Buy(address user, address registrar, uint256 deiAmount, uint256 price, uint256 collateralAmount, uint256 feeAmount);
    event Sell(address user, address registrar, uint256 registrarAmount, uint256 price, uint256 collateralAmount, uint256 feeAmount);
    event ShareSet(uint256 deusDaoShare, uint256 spiritSwapShare);
    event WithdrawFee(uint256 deusShare, uint256 spiritswapShare);

    constructor (
        uint256 minimumRequiredSignature_,
        uint256 virtualReserve_,
        address collateralToken_,
        address spiritSwapDao_,
        address deusDao_
    ) {
        minimumRequiredSignature = minimumRequiredSignature_;
        virtualReserve = virtualReserve_;
        deiContract = collateralToken_;
        spiritSwapDao = spiritSwapDao_;
        deusDao = deusDao_;
    }

    /// @notice This function use pool feature to manage buyback and recollateralize on DEI minter pool
    /// @dev simulates the collateral in the contract
    /// @param collat_usd_price pool's collateral price (is 1e6) (decimal is 6)
    /// @return amount of collateral in the contract
    function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
        if (!useVirtualReserve) return 0;
        uint256 collateralRatio = IDEIStablecoin(deiContract).global_collateral_ratio();
        return (virtualReserve * collateralRatio) / 1e6;
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
    /// @param fee trading fee
    /// @param price synthetic price
    /// @param action 0 is sell & 1 is buy
    /// @return amountIn for trading
    function getAmountIn(uint256 amountOut, uint256 fee, uint256 price, uint256 action) public view returns (uint256 amountIn) {
        if (action == 0) {  // sell synthetic token
            amountIn = amountOut * price / scale - fee;  // x = y * (price) * (1 / 1 - fee)
        } else {  // buy synthetic token
            amountIn = amountOut * scale * scale / (price * (scale - fee));  // x = y * / (price * (1 - fee))
        }
    }

    /// @notice view functions for frontend
    /// @param amountIn amount that you want sell
    /// @param fee trading fee
    /// @param price synthetic price
    /// @param action 0 is sell & 1 is buy
    /// @return amountOut for trading
    function getAmountOut(uint256 amountIn, uint256 fee, uint256 price, uint256 action) public view returns (uint256 amountOut) {
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
    /// @param _user collateral will be send to the _user
    /// @param registrar synthetic token address
    /// @param amountIn synthetic token amount (decimal is 18)
    /// @param fee trading fee
    /// @param expireBlock signature expire time
    /// @param price synthetic token price
    /// @param _reqId muon request id
    /// @param sigs muon network's TSS signatures
    function sellFor(
        address _user,
        address registrar,
        uint256 amountIn,
        uint256 fee,
        uint256 expireBlock,
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    )
        external
    {
        require(
            sigs.length >= minimumRequiredSignature,
            "SYNCHRONIZER: insufficient number of signatures"
        );
        require(amountIn > 0, "SYNCHRONIZER: amount should be bigger than 0");

        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    registrar, 
                    price, 
                    fee, 
                    expireBlock, 
                    uint256(0),
                    getChainID(),
                    APP_ID
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

        withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

        IRegistrar(registrar).burn(msg.sender, amountIn);

        uint256 deiAmount = collateralAmount - feeAmount;
        IDEIStablecoin(deiContract).pool_mint(_user, deiAmount);
        if (useVirtualReserve) virtualReserve += deiAmount;

        emit Sell(_user, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice to buy the synthetic tokens
    /// @dev SchnorrSign is a TSS structure
    /// @param _user synthetic token will be send to the _user
    /// @param registrar synthetic token address
    /// @param amountIn dei token amount (decimal is 18)
    /// @param fee trading fee
    /// @param expireBlock signature expire time
    /// @param price synthetic token price
    /// @param _reqId muon request id
    /// @param sigs muon network's TSS signatures
    function buyFor(
        address _user,
        address registrar,
        uint256 amountIn,
        uint256 fee,
        uint256 expireBlock,
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    )
        external
    {
        require(
            sigs.length >= minimumRequiredSignature,
            "SYNCHRONIZER: insufficient number of signatures"
        );
        require(amountIn > 0, "SYNCHRONIZER: amount should be bigger than 0");

        {
            bytes32 hash = keccak256(
                abi.encodePacked(
                    registrar, 
                    price, 
                    fee, 
                    expireBlock, 
                    uint256(1),
                    getChainID(),
                    APP_ID
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
        uint256 registrarAmount = collateralAmount * scale / price;

        withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

        IDEIStablecoin(deiContract).pool_burn_from(msg.sender, amountIn);
        if (useVirtualReserve) virtualReserve -= amountIn;

        IRegistrar(registrar).mint(_user, registrarAmount);

        emit Buy(_user, registrar, amountIn, price, collateralAmount, feeAmount);
    }

    /// @notice withdraw accumulated trading fee by DAO
    /// @dev fee will be minted in DEI
    function withdrawFee() external onlyOwner {
        uint256 deusDaoAmount = withdrawableFeeAmount * deusDaoShare / (deusDaoShare + spiritSwapDaoShare);
        uint256 spiritSwapDaoAmount = withdrawableFeeAmount * spiritSwapDaoShare / (deusDaoShare + spiritSwapDaoShare);
        IDEIStablecoin(deiContract).pool_mint(deusDao, deusDaoAmount);
        IDEIStablecoin(deiContract).pool_mint(spiritSwapDao, spiritSwapDaoAmount);
        withdrawableFeeAmount = 0;
        emit WithdrawFee(deusDaoAmount, spiritSwapDaoAmount);
    }

    /// @notice changes minimum required signatures in trading functions by DAO
    /// @param minimumRequiredSignature_ number of required signatures
    function setMinimumRequiredSignature(uint256 minimumRequiredSignature_) external onlyOwner {
        minimumRequiredSignature = minimumRequiredSignature_;
    }

    function setScale(uint scale_) external onlyOwner {
        scale = scale_;
    }

    /// @notice changes deus dao
    /// @param deusDao_ new dao address
    function setDeusDao(address deusDao_) external {
        require(deusDao == msg.sender, "SYNCHRONIZER: Caller is not deus dao");
        deusDao = deusDao_;
    }

    /// @notice changes spirit swap dao
    /// @param spiritSwapDao_ new dao address
    function setSpiritSwapDao(address spiritSwapDao_) external {
        require(spiritSwapDao == msg.sender, "SYNCHRONIZER: Caller is not spiritswap dao");
        spiritSwapDao = spiritSwapDao_;
    }

    /// @notice to change shares
    /// @param deusDaoShare_ new share of deus dao
    /// @param spiritSwapShare_ new share of spiritswap dao
    function setShares(uint256 deusDaoShare_, uint256 spiritSwapShare_) external onlyOwner {
        deusDaoShare = deusDaoShare_;
        spiritSwapDaoShare = spiritSwapShare_;
        emit ShareSet(deusDaoShare_, spiritSwapShare_);        
    }

    /// @notice changes muon's app id by DAO
    /// @dev each app becomes different from others by app id
    /// @param APP_ID_ muon's app id
    function setAppId(uint8 APP_ID_) external onlyOwner {
        APP_ID = APP_ID_;
    }

    function setvirtualReserve(uint256 virtualReserve_) external onlyOwner {
        virtualReserve = virtualReserve_;
    }

    function setMuonContract(address muonContract_) external onlyOwner {
        muonContract = muonContract_;
    }

    /// @dev it affects buyback and recollateralize functions on DEI minter pool 
    function toggleUseVirtualReserve() external onlyOwner {
        useVirtualReserve = !useVirtualReserve;
    }
}

//Dar panah khoda
