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

import "@openzeppelin/contracts/access/AccessControl.sol";
import "./IDEIStablecoin.sol";
import "./IRegistrar.sol";


contract Synchronizer is AccessControl {
	// roles
	bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
	bytes32 public constant FEE_WITHDRAWER_ROLE = keccak256("FEE_WITHDRAWER_ROLE");

	// variables
	uint256 public minimumRequiredSignature;
	uint256 public scale = 1e18;
	uint256 public withdrawableFeeAmount;
	uint256 public bridgeReserve;
	IDEIStablecoin public dei;

	// events
	event Buy(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event Sell(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event WithdrawFee(uint256 amount, address recipient);

	constructor (
		uint256 _minimumRequiredSignature,
		uint256 _bridgeReserve,
		address _collateralToken
	) {
		minimumRequiredSignature = _minimumRequiredSignature;
		bridgeReserve = _bridgeReserve;
		dei = IDEIStablecoin(_collateralToken);
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(FEE_WITHDRAWER_ROLE, msg.sender);
	}

	// This function use pool feature to handle buyback and recollateralize on DEI minter pool
    function collatDollarBalance(uint256 collat_usd_price) public view returns (uint256) {
        uint256 collateralRatio = dei.global_collateral_ratio();
        return (bridgeReserve * collateralRatio) / 1e6;
    }

	function sellFor(
		address _user,
		uint256 multiplier,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256[] memory blockNos,
		uint256[] memory prices,
		uint8[] memory v,
		bytes32[] memory r,
		bytes32[] memory s
	)
		external
	{
		uint256 price = prices[0];
		address lastOracle;

		for (uint256 index = 0; index < minimumRequiredSignature; ++index) {
			require(blockNos[index] >= block.number, "Signature is expired");
			if(prices[index] < price) {
				price = prices[index];
			}
			address oracle = getSigner(registrar, 8, multiplier, fee, blockNos[index], prices[index], v[index], r[index], s[index]);
			require(hasRole(ORACLE_ROLE, oracle), "signer is not an oracle");

			require(oracle > lastOracle, "Signers are same");
			lastOracle = oracle;
		}

		//---------------------------------------------------------------------------------

		uint256 collateralAmount = amount * price / scale;
		uint256 feeAmount = collateralAmount * fee / scale;

		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		IRegistrar(registrar).burn(msg.sender, amount);

		dei.pool_mint(_user, collateralAmount - feeAmount);

		emit Sell(_user, registrar, amount, collateralAmount, feeAmount);
	}

	function buyFor(
		address _user,
		uint256 multiplier,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256[] memory blockNos,
		uint256[] memory prices,
		uint8[] memory v, 
		bytes32[] memory r,
		bytes32[] memory s
	)
		external
	{
		uint256 price = prices[0];
        address lastOracle;
        
		for (uint256 index = 0; index < minimumRequiredSignature; ++index) {
			require(blockNos[index] >= block.number, "Signature is expired");
			if(prices[index] > price) {
				price = prices[index];
			}
			address oracle = getSigner(registrar, 9, multiplier, fee, blockNos[index], prices[index], v[index], r[index], s[index]);
			require(hasRole(ORACLE_ROLE, oracle), "Signer is not an oracle");

			require(oracle > lastOracle, "Signers are same");
			lastOracle = oracle;
		}

		//---------------------------------------------------------------------------------
		uint256 collateralAmount = amount * price / scale;
		uint256 feeAmount = collateralAmount * fee / scale;

		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		dei.pool_burn_from(msg.sender, collateralAmount + feeAmount);

		IRegistrar(registrar).mint(_user, amount);

		emit Buy(_user, registrar, amount, collateralAmount, feeAmount);
	}

	function getSigner(
		address registrar,
		uint256 isBuy,
		uint256 multiplier,
		uint256 fee,
		uint256 blockNo,
		uint256 price,
		uint8 v,
		bytes32 r,
		bytes32 s
	)
		pure
		internal
		returns (address)
	{
        bytes32 message = prefixed(keccak256(abi.encodePacked(registrar, isBuy, multiplier, fee, blockNo, price)));
		return ecrecover(message, v, r, s);
    }

	function prefixed(
		bytes32 hash
	)
		internal
		pure
		returns(bytes32)
	{
        return keccak256(abi.encodePacked("\x19Ethereum Signed Message:\n32", hash));
    }

	//---------------------------------------------------------------------------------------

	function withdrawFee(uint256 _amount, address _recipient) external {
		require(hasRole(FEE_WITHDRAWER_ROLE, msg.sender), "Caller is not a FeeWithdrawer");
		withdrawableFeeAmount = withdrawableFeeAmount - _amount;
		dei.pool_mint(_recipient, _amount);
		emit WithdrawFee(_amount, _recipient);
	}

	function setMinimumRequiredSignature(uint256 _minimumRequiredSignature) external {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
		minimumRequiredSignature = _minimumRequiredSignature;
	}

	function setScale(uint _scale) external {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
		scale = _scale;
	}

	function setBridgeReserve(uint256 bridgeReserve_) external {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
        bridgeReserve = bridgeReserve_;
    }
}

//Dar panah khoda
