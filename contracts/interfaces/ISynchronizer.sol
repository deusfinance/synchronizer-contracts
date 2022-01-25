// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IMuonV02.sol";

interface ISynchronizer {

    function muonContract() external view returns(address);
    function minimumRequiredSignature() external view returns(uint256);
    function scale() external view returns(uint256);
    function withdrawableFeeAmount() external view returns(uint256);
    function virtualReserve() external view returns(uint256);
    function APP_ID() external view returns(uint8);
    function useVirtualReserve() external view returns(bool);
    function deiContract() external view returns(address);
    function collatDollarBalance(uint256 collat_usd_price) external view returns (uint256);
	function getChainID() external view returns (uint256);
	function getAmountIn(uint256 amountOut, uint256 fee, uint256 price, uint256 action) external view returns (uint256 amountIn);
	function getAmountOut(uint256 amountIn, uint256 fee, uint256 price, uint256 action) external view returns (uint256 amountOut);
	function sellFor(
		address _user,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256 expireBlock,
		uint256 price,
		bytes calldata _reqId,
		SchnorrSign[] calldata sigs
	) external;
	function buyFor(
		address _user,
		address registrar,
		uint256 amount,
		uint256 fee,
		uint256 expireBlock,
		uint256 price,
		bytes calldata _reqId,
		SchnorrSign[] calldata sigs
	) external;
	function withdrawFee(uint256 amount_, address recipient_) external;
	function setMinimumRequiredSignature(uint256 _minimumRequiredSignature) external;
	function setScale(uint scale_) external;
	function setAppId(uint8 APP_ID_) external;
	function setvirtualReserve(uint256 virtualReserve_) external;
	function setMuonContract(address muonContract_) external;
	function toggleUseVirtualReserve() external;
}

//Dar panah khoda
