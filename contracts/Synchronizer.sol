// Be name Khoda
// Bime Abolfazl

// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

import "@openzeppelin/contracts/access/AccessControl.sol";

interface IERC20 {
	function totalSupply() external view returns (uint256);
	function balanceOf(address account) external view returns (uint256);
	function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
	function transfer(address recipient, uint256 amount) external returns (bool);
	function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
}

interface Registrar {
	function totalSupply() external view returns (uint256);
	function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
}

contract Synchronizer is AccessControl {
	// roles
	bytes32 public constant ORACLE_ROLE = keccak256("ORACLE_ROLE");
	bytes32 public constant FEE_WITHDRAWER_ROLE = keccak256("FEE_WITHDRAWER_ROLE");
	bytes32 public constant COLLATERAL_WITHDRAWER_ROLE = keccak256("COLLATERAL_WITHDRAWER_ROLE");
	bytes32 public constant REMAINING_DOLLAR_CAP_SETTER_ROLE = keccak256("REMAINING_DOLLAR_CAP_SETTER_ROLE");

	// variables
	uint256 public minimumRequiredSignature;
	IERC20 public collateralToken;
	uint256 public remainingDollarCap;
	uint256 public scale = 1e18;
	uint256 public collateralScale = 1e10;
	uint256 public withdrawableFeeAmount;

	// events
	event Buy(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event Sell(address user, address registrar, uint256 registrarAmount, uint256 collateralAmount, uint256 feeAmount);
	event WithdrawFee(uint256 amount, address recipient);
	event WithdrawCollateral(uint256 amount, address recipient);

	constructor (
		uint256 _remainingDollarCap,
		uint256 _minimumRequiredSignature,
		address _collateralToken
	)
	{
		remainingDollarCap = _remainingDollarCap;
		minimumRequiredSignature = _minimumRequiredSignature;
		collateralToken = IERC20(_collateralToken);
		_setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
		_setupRole(FEE_WITHDRAWER_ROLE, msg.sender);
		_setupRole(COLLATERAL_WITHDRAWER_ROLE, msg.sender);
	
	}

	function setMinimumRequiredSignature(uint256 _minimumRequiredSignature) external {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
		minimumRequiredSignature = _minimumRequiredSignature;
	}

	function setCollateralToken(address _collateralToken) external {
		require(hasRole(DEFAULT_ADMIN_ROLE, msg.sender), "Caller is not an admin");
		collateralToken = IERC20(_collateralToken);
	}

	function setRemainingDollarCap(uint256 _remainingDollarCap) external {
		require(hasRole(REMAINING_DOLLAR_CAP_SETTER_ROLE, msg.sender), "Caller is not a remainingDollarCap setter");
		remainingDollarCap = _remainingDollarCap;
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

		uint256 collateralAmount = amount * price / (scale * collateralScale);
		uint256 feeAmount = collateralAmount * fee / scale;

		remainingDollarCap = remainingDollarCap + (collateralAmount * multiplier);

		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		Registrar(registrar).burn(msg.sender, amount);

		collateralToken.transfer(_user, collateralAmount - feeAmount);

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
		uint256 collateralAmount = amount * price / (scale * collateralScale);
		uint256 feeAmount = collateralAmount * fee / scale;

		remainingDollarCap = remainingDollarCap - (collateralAmount * multiplier);
		withdrawableFeeAmount = withdrawableFeeAmount + feeAmount;

		collateralToken.transferFrom(msg.sender, address(this), collateralAmount + feeAmount);

		Registrar(registrar).mint(_user, amount);

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
		collateralToken.transfer(_recipient, _amount);

		emit WithdrawFee(_amount, _recipient);
	}

	function withdrawCollateral(uint256 _amount, address _recipient) external {
		require(hasRole(COLLATERAL_WITHDRAWER_ROLE, msg.sender), "Caller is not a CollateralWithdrawer");

		collateralToken.transfer(_recipient, _amount);

		emit WithdrawCollateral(_amount, _recipient);
	}

}

//Dar panah khoda
