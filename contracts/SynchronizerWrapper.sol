// Be name Khoda
// SPDX-License-Identifier: MIT
pragma solidity 0.8.9;
pragma abicoder v2;
// =================================================================================================================
//  _|_|_|    _|_|_|_|  _|    _|    _|_|_|      _|_|_|_|  _|                                                       |
//  _|    _|  _|        _|    _|  _|            _|            _|_|_|      _|_|_|  _|_|_|      _|_|_|    _|_|       |
//  _|    _|  _|_|_|    _|    _|    _|_|        _|_|_|    _|  _|    _|  _|    _|  _|    _|  _|        _|_|_|_|     |
//  _|    _|  _|        _|    _|        _|      _|        _|  _|    _|  _|    _|  _|    _|  _|        _|           |
//  _|_|_|    _|_|_|_|    _|_|    _|_|_|        _|        _|  _|    _|    _|_|_|  _|    _|    _|_|_|    _|_|_|     |
// =================================================================================================================
// ========================= DEIProxy ============================
// ===============================================================
// DEUS Finance: https://github.com/DeusFinance

// Primary Author(s)
// Kazem Gh
// Miko

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/ISynchronizer.sol";
import "./interfaces/IDEIProxyFantom.sol";

struct WrapperInput {
	address partnerId;
	address receipient;
	address registrar;
	uint256 price;
	uint256 expireBlock;
	bytes reqId;
	SchnorrSign[] sigs;
}

struct WrapperViewInput {
	address partnerId;
	address registrar;
	uint256 amountIn;
	uint256 price;
	uint256 action;
}

contract SynchronizerWrapper {
	
	/* ========== STATE VARIABLES ========== */

	address public uniswapRouter;
	address public dei;
	address public usdc;
	address public deiProxy;
	address public synchronizer;

	uint public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;

	/* ========== CONSTRUCTOR ========== */

	constructor(
		address uniswapRouter_,
		address dei_,
		address usdc_,
		address deiProxy_,
		address synchronizer_
	) {
		uniswapRouter = uniswapRouter_;
		dei = dei_;
		usdc = usdc_;
		deiProxy = deiProxy_;
	    synchronizer = synchronizer_;

		IERC20(usdc).approve(deiProxy, type(uint256).max);
		IERC20(dei).approve(synchronizer, type(uint256).max);
	}


	/* ========== PUBLIC FUNCTIONS ========== */
	function sell(
		uint256 amountIn,
		WrapperInput memory input,
		uint256 minAmountOut,
		address[] calldata path
	) external {
			IERC20(input.registrar).transferFrom(msg.sender, address(this), amountIn);
			if (IERC20(input.registrar).allowance(address(this), synchronizer) < amountIn) {
				IERC20(input.registrar).approve(synchronizer, type(uint).max);
			}
			uint deiAmount = ISynchronizer(synchronizer).sellFor(
				input.partnerId,
				address(this),
				input.registrar,
				amountIn,
				input.price,
				input.expireBlock,
				input.reqId,
				input.sigs
			);
			uint amountOut = deiAmount;
			if(path[path.length -1] != dei){
				amountOut = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(deiAmount, 0, path, input.receipient, deadline)[path.length -1];
			}
			require(amountOut >= minAmountOut, "INSUFFICIENT_AMOUNT_OUT");
	}

	function buyWithMinting(
		WrapperInput memory input,
		IDEIProxy.ProxyInput memory proxyInput,
		uint256 minAmountOut,
		address[] calldata path
	) external {
			IERC20(path[0]).transferFrom(msg.sender, address(this), proxyInput.amountIn);

			uint256 deiAmount = proxyInput.amountIn;
			if(path[0] == usdc){
				deiAmount = IDEIProxy(deiProxy).USDC2DEI(proxyInput);
			}else if(path[0] != dei){
				if (IERC20(path[0]).allowance(address(this), deiProxy) < proxyInput.amountIn) {
					IERC20(path[0]).approve(deiProxy, type(uint).max);
				}
				deiAmount = IDEIProxy(deiProxy).ERC202DEI(proxyInput, path);
			}
			require(deiAmount >= minAmountOut, "INSUFFICIENT_AMOUNT_OUT");
			ISynchronizer(synchronizer).buyFor(
				input.partnerId,
				input.receipient,
				input.registrar,
				deiAmount,
				input.price,
				input.expireBlock,
				input.reqId,
				input.sigs
			);
	}
	
	function buy(
		uint256 amountIn,
		WrapperInput memory input,
		uint256 minAmountOut,
		address[] calldata path
	) external {
			IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
			uint256 deiAmount = amountIn;
			if(path[0] != dei){
				if (IERC20(path[0]).allowance(address(this), uniswapRouter) < amountIn) {
					IERC20(path[0]).approve(uniswapRouter, type(uint).max);
				}
				deiAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(amountIn, 0, path, address(this), deadline)[path.length -1];
			}
			require(deiAmount >= minAmountOut, "INSUFFICIENT_AMOUNT_OUT");
			ISynchronizer(synchronizer).buyFor(
				input.partnerId,
				input.receipient,
				input.registrar,
				deiAmount,
				input.price,
				input.expireBlock,
				input.reqId,
				input.sigs
			);
			
	}

	function buyWithMintingFromETH(
		WrapperInput memory input,
		IDEIProxy.ProxyInput memory proxyInput,
		uint256 minAmountOut,
		address[] calldata path
	) external payable {
			uint256 deiAmount = IDEIProxy(deiProxy).Nativecoin2DEI{value: msg.value}(proxyInput, path);
			require(deiAmount >= minAmountOut, "INSUFFICIENT_AMOUNT_OUT");
			ISynchronizer(synchronizer).buyFor(
				input.partnerId,
				input.receipient,
				input.registrar,
				deiAmount,
				input.price,
				input.expireBlock,
				input.reqId,
				input.sigs
			);
	}
	
	function buyWithETH(
		WrapperInput memory input,
		uint256 minAmountOut,
		address[] calldata path
	) external payable {			
			uint256 deiAmount = IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{value: msg.value}(0, path, address(this), deadline)[path.length -1];
			require(deiAmount >= minAmountOut, "INSUFFICIENT_AMOUNT_OUT");
			ISynchronizer(synchronizer).buyFor(
				input.partnerId,
				input.receipient,
				input.registrar,
				deiAmount,
				input.price,
				input.expireBlock,
				input.reqId,
				input.sigs
			);
			
	}
	/* ========== VIEWS ========== */

	function getAmountsOutWithMinting(
		WrapperViewInput memory syncInput, 
		uint256 deusPriceUSD, 
		uint256 collateralPrice, 
		address[] calldata path
	) public view returns (
		uint256 amountOut, 
		uint usdcForMintAmount, 
		uint deusNeededAmount
	){
		if(syncInput.action == 0){
			uint256 deiAmount = ISynchronizer(synchronizer)
				.getAmountOut(
					syncInput.partnerId, 
					syncInput.registrar, 
					syncInput.amountIn, 
					syncInput.price, 
					syncInput.action
				);
			if(path[path.length - 1] != dei){
				amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(deiAmount, path)[path.length - 1];
			}else{
				amountOut = deiAmount;
			}
		}
		else{
			if(path[0] != dei){
				(syncInput.amountIn, usdcForMintAmount, deusNeededAmount) = IDEIProxy(deiProxy)
					.getAmountsOut(
						syncInput.amountIn,
						deusPriceUSD,
						collateralPrice,
						path
					);
			}
			// buy stock with dei
			amountOut = ISynchronizer(synchronizer)
				.getAmountOut(
					syncInput.partnerId, 
					syncInput.registrar, 
					syncInput.amountIn, 
					syncInput.price, 
					syncInput.action
				);
		}
	}

	function getAmountsOut(
		WrapperViewInput memory syncInput, 
		address[] calldata path
	) public view returns (uint256 amountOut){
		if(syncInput.action == 0){
			uint256 deiAmount = ISynchronizer(synchronizer)
				.getAmountOut(
					syncInput.partnerId, 
					syncInput.registrar, 
					syncInput.amountIn, 
					syncInput.price, 
					syncInput.action
				);
			if(path[path.length -1] != dei){
				amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(deiAmount, path)[ path.length - 1 ];
			}else{
				amountOut = deiAmount;
			}
		}
		else{
			if(path[0] != dei){
				syncInput.amountIn = IUniswapV2Router02(uniswapRouter).getAmountsOut(syncInput.amountIn, path)[path.length - 1]; 
			}
			// buy stock with dei
			amountOut = ISynchronizer(synchronizer)
				.getAmountOut(
					syncInput.partnerId, 
					syncInput.registrar, 
					syncInput.amountIn, 
					syncInput.price, 
					syncInput.action
				);
		}
	}
}

// Dar panahe Khoda
