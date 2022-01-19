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
import "./interfaces/IMuonV02.sol";
import "./interfaces/IDEIStablecoin.sol";
import "./interfaces/IRegistrar.sol";


contract Synchronizer is ISynchronizer, Ownable {
	using ECDSA for bytes32;

	// variables
	address public muonContract;  // address of muon verifier contract
	address public deiContract;
	uint256 public minimumRequiredSignature;  // number of signatures that required
	uint256 public scale = 1e18;  // used for math
	uint256 public withdrawableFeeAmount;  // trading fee amount
	uint256 public virtualReserve;
	uint8 public APP_ID;  // muon's app id
	bool public useVirtualReserve;

	// events
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

	// This function use pool feature to handle buyback and recollateralize on DEI minter pool
    function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
        uint256 collateralRatio = IDEIStablecoin(deiContract).global_collateral_ratio();
        return (virtualReserve * collateralRatio) / 1e6;
    }

	function getChainID() public view returns (uint256) {
        uint256 id;
        assembly {
            id := chainid()
        }
        return id;
    }

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
            "insufficient number of signatures"
        );

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
                "not verified"
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
            "insufficient number of signatures"
        );
		require(amount > 0, "amount should be bigger than 0");

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
                "not verified"
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


	function withdrawFee(uint256 amount_, address recipient_) external onlyOwner {
		withdrawableFeeAmount = withdrawableFeeAmount - amount_;
		IDEIStablecoin(deiContract).pool_mint(recipient_, amount_);
		emit WithdrawFee(amount_, recipient_);
	}

	function setMinimumRequiredSignature(uint256 _minimumRequiredSignature) external onlyOwner {
		minimumRequiredSignature = _minimumRequiredSignature;
	}

	function setScale(uint scale_) external onlyOwner {
		scale = scale_;
	}

	function setAppId(uint8 APP_ID_) external onlyOwner {
		APP_ID = APP_ID_;
	}

	function setvirtualReserve(uint256 virtualReserve_) external onlyOwner {
        virtualReserve = virtualReserve_;
    }

	function setMuonContract(address muonContract_) external onlyOwner {
		muonContract = muonContract_;
	}

	function toggleUseVirtualReserve() external onlyOwner {
		useVirtualReserve = !useVirtualReserve;
	}
}

//Dar panah khoda
