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
	uint256 public minimumRequiredSignature;  // number of signatures that required
	uint256 public scale = 1e18;  // used for math
	uint256 public withdrawableFeeAmount;  // trading fee amount
	uint256 public virtualReserve;
	uint8 public APP_ID;  // muon's app id
	bool public useVirtualReserve;

	event Buy(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event Sell(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event WithdrawFee(uint256 amount, address recipient);

	constructor (
		uint256 _minimumRequiredSignature,
		uint256 _virtualReserve,
		address _collateralToken
	) {
		minimumRequiredSignature = _minimumRequiredSignature;
		virtualReserve = _virtualReserve;
		deiContract = _collateralToken;
	}

	/// @notice This function use pool feature to manage buyback and recollateralize on DEI minter pool
	/// @dev simulates the collateral in the contract
	/// @param collat_usd_price pool's collateral price (is 1e6) (decimal is 6)
	/// @return amount of collateral in the contract
    function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
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

	/// @notice sell the synthetic tokens
	/// @dev SchnorrSign is a TSS structure
	/// @param _user collateral will be send to the _user
	/// @param registrar synthetic token address
	/// @param amount synthetic token amount (decimal is 18)
	/// @param fee trading fee
	/// @param expireBlock signature expire time
	/// @param price synthetic token price
	/// @param _reqId muon request id
	/// @param sigs muon network's TSS signatures
	function sellFor(
		address _user,
		address registrar,
		uint256 amount,
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
		require(amount > 0, "SYNCHRONIZER: amount should be bigger than 0");

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

		uint256 collateralAmount = amount * price / scale;
		uint256 feeAmount = collateralAmount * fee / scale;

		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		IRegistrar(registrar).burn(msg.sender, amount);

		uint256 deiAmount = collateralAmount - feeAmount;
		IDEIStablecoin(deiContract).pool_mint(_user, deiAmount);
		if (useVirtualReserve) virtualReserve += deiAmount;

		emit Sell(_user, registrar, amount, collateralAmount, feeAmount);
	}

	/// @notice buy the synthetic tokens
	/// @dev SchnorrSign is a TSS structure
	/// @param _user synthetic token will be send to the _user
	/// @param registrar synthetic token address
	/// @param amount synthetic token amount (decimal is 18)
	/// @param fee trading fee
	/// @param expireBlock signature expire time
	/// @param price synthetic token price
	/// @param _reqId muon request id
	/// @param sigs muon network's TSS signatures
	function buyFor(
		address _user,
		address registrar,
		uint256 amount,
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
		require(amount > 0, "SYNCHRONIZER: amount should be bigger than 0");

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

		uint256 collateralAmount = amount * price / scale;
		uint256 feeAmount = collateralAmount * fee / scale;

		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		uint256 deiAmount = collateralAmount + feeAmount;
		IDEIStablecoin(deiContract).pool_burn_from(msg.sender, deiAmount);
		if (useVirtualReserve) virtualReserve -= deiAmount;

		IRegistrar(registrar).mint(_user, amount);

		emit Buy(_user, registrar, amount, collateralAmount, feeAmount);
	}

	/// @notice withdraw accumulated trading fee by DAO
	/// @dev fee will be minted in DEI
	/// @param amount_ fee amount that DAO want to withdraw
	/// @param recipient_ receiver of fee
	function withdrawFee(uint256 amount_, address recipient_) external onlyOwner {
		withdrawableFeeAmount = withdrawableFeeAmount - amount_;
		IDEIStablecoin(deiContract).pool_mint(recipient_, amount_);
		emit WithdrawFee(amount_, recipient_);
	}

	/// @notice changes minimum required signatures in trading functions by DAO
	/// @param _minimumRequiredSignature number of required signatures
	function setMinimumRequiredSignature(uint256 _minimumRequiredSignature) external onlyOwner {
		minimumRequiredSignature = _minimumRequiredSignature;
	}

	function setScale(uint scale_) external onlyOwner {
		scale = scale_;
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
