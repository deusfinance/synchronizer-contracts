// Be name Khoda
// Bime Abolfazl
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;
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

// Reviewer(s)
// Vahid: https://github.com/vahid-dev

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./interfaces/IUniswapV2Router02.sol";
import "./interfaces/ISynchronizer.sol";
import "./interfaces/IDEIProxy.sol";
import "./interfaces/ISynchronizerWrapper.sol";

contract SynchronizerWrapper is ISynchronizerWrapper {
    /* ========== STATE VARIABLES ========== */

    address public uniswapRouter;  // Spiritswap router on fantom
    address public dei;  // address of DEI token
    address public usdc;  // address of USDC token
    address public deiProxy;  // address of DEI Proxy contract
    address public synchronizer;  // address of synchronizer main contract
    uint256 public deadline = 0xf000000000000000000000000000000000000000000000000000000000000000;  // used for swaps on spiritswap router

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

    /// @notice to sell registrars to the ERC20 tokens on Spiritswap
    /// @param amountIn registrar amount
    /// @param input WrapperInput used in synchronizer main contract
    /// @param minAmountOut minimum amount of token that you want at the end
    /// @param path path used in Spiritswap router (default path is [0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3])
    function sell(
        uint256 amountIn,
        WrapperInput memory input,
        uint256 minAmountOut,
        address[] calldata path
    ) external {
        IERC20(input.registrar).transferFrom(msg.sender, address(this), amountIn);
        if (IERC20(input.registrar).allowance(address(this), synchronizer) < amountIn) {
            IERC20(input.registrar).approve(synchronizer, type(uint256).max);
        }
        uint256 deiAmount = ISynchronizer(synchronizer).sellFor(
            input.partnerId,
            address(this),
            input.registrar,
            amountIn,
            input.price,
            input.expireBlock,
            input.reqId,
            input.sigs
        );
        uint256 amountOut = deiAmount;
        if (path[path.length - 1] != dei) {
            amountOut = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
                deiAmount,
                0,
                path,
                input.receipient,
                deadline
            )[path.length - 1];
        }
        require(amountOut >= minAmountOut, "SynchronizerWrapper: INSUFFICIENT_AMOUNT_OUT");
    }

    /// @notice to buy registrars via ERC20 tokens on Spiritswap through minting dei
    /// @param input WrapperInput used in synchronizer main contract
    /// @param proxyInput ProxyInput used in DEIProxy contract to mint DEI
    /// @param minAmountOut minimum amount of token that you want at the end
    /// @param path path used in Spiritswap router (default path is [0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3])
    function buyWithMinting(
        WrapperInput memory input,
        IDEIProxy.ProxyInput memory proxyInput,
        uint256 minAmountOut,
        address[] calldata path
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), proxyInput.amountIn);

        uint256 deiAmount = proxyInput.amountIn;
        if (path[0] == usdc) {
            deiAmount = IDEIProxy(deiProxy).USDC2DEI(proxyInput);
        } else if (path[0] != dei) {
            if (IERC20(path[0]).allowance(address(this), deiProxy) < proxyInput.amountIn) {
                IERC20(path[0]).approve(deiProxy, type(uint256).max);
            }
            deiAmount = IDEIProxy(deiProxy).ERC202DEI(proxyInput, path);
        }
        require(deiAmount >= minAmountOut, "SynchronizerWrapper: INSUFFICIENT_AMOUNT_OUT");
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

    /// @notice to buy registrars via ERC20 tokens on Spiritswap
    /// @dev minimum amount of dei tokens on Spiritswap
    /// @param amountIn amount of tokens that you want buy registrars
    /// @param input WrapperInput used in synchronizer main contract
    /// @param minAmountOut minimum amount of dei that need to buy registrars
    /// @param path path used in Spiritswap router (default path is [0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3])
    function buy(
        uint256 amountIn,
        WrapperInput memory input,
        uint256 minAmountOut,
        address[] calldata path
    ) external {
        IERC20(path[0]).transferFrom(msg.sender, address(this), amountIn);
        uint256 deiAmount = amountIn;
        if (path[0] != dei) {
            if (IERC20(path[0]).allowance(address(this), uniswapRouter) < amountIn) {
                IERC20(path[0]).approve(uniswapRouter, type(uint256).max);
            }
            deiAmount = IUniswapV2Router02(uniswapRouter).swapExactTokensForTokens(
                amountIn,
                0,
                path,
                address(this),
                deadline
            )[path.length - 1];
        }
        require(deiAmount >= minAmountOut, "SynchronizerWrapper: INSUFFICIENT_AMOUNT_OUT");
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

    /// @notice to buy registrars via ETH (native coin) through minting DEI
    /// @param input WrapperInput used in synchronizer main contract
    /// @param proxyInput amount of tokens that you want buy registrars
    /// @param minAmountOut minimum amount of dei that need to buy registrars
    /// @param path path used in Spiritswap router (default path is [0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3])
    function buyWithMintingFromETH(
        WrapperInput memory input,
        IDEIProxy.ProxyInput memory proxyInput,
        uint256 minAmountOut,
        address[] calldata path
    ) external payable {
        uint256 deiAmount = IDEIProxy(deiProxy).Nativecoin2DEI{value: msg.value}(proxyInput, path);
        require(deiAmount >= minAmountOut, "SynchronizerWrapper: INSUFFICIENT_AMOUNT_OUT");
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

    /// @notice to buy registrars via ETH (native coin)
    /// @param input WrapperInput used in synchronizer main contract
    /// @param minAmountOut minimum amount of dei that need to buy registrars
    /// @param path path used in Spiritswap router (default path is [0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3])
    function buyWithETH(
        WrapperInput memory input,
        uint256 minAmountOut,
        address[] calldata path
    ) external payable {
        uint256 deiAmount = IUniswapV2Router02(uniswapRouter).swapExactETHForTokens{value: msg.value}(
            0,
            path,
            address(this),
            deadline
        )[path.length - 1];
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

    /// @notice returns registrar amount throught minting DEI or returns DEI amount when selling registrars
    /// @param syncInput WrapperInput used in synchronizer main contract
    /// @param deusPriceUSD deus twap price is available at deus oracles
    /// @param collateralPrice collateral price (is 1e6)
    /// @param path path used in Spiritswap router (default path is [0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3])
    function getAmountsOutWithMinting(
        WrapperViewInput memory syncInput,
        uint256 deusPriceUSD,
        uint256 collateralPrice,
        address[] calldata path
    )
        public
        view
        returns (
            uint256 amountOut,
            uint256 usdcForMintAmount,
            uint256 deusNeededAmount
        )
    {
        if (syncInput.action == 0) {
            uint256 deiAmount = ISynchronizer(synchronizer).getAmountOut(
                syncInput.partnerId,
                syncInput.registrar,
                syncInput.amountIn,
                syncInput.price,
                syncInput.action
            );
            if (path[path.length - 1] != dei) {
                amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(deiAmount, path)[path.length - 1];
            } else {
                amountOut = deiAmount;
            }
        } else {
            if (path[0] != dei) {
                (syncInput.amountIn, usdcForMintAmount, deusNeededAmount) = IDEIProxy(deiProxy).getAmountsOut(
                    syncInput.amountIn,
                    deusPriceUSD,
                    collateralPrice,
                    path
                );
            }
            // buy stock with dei
            amountOut = ISynchronizer(synchronizer).getAmountOut(
                syncInput.partnerId,
                syncInput.registrar,
                syncInput.amountIn,
                syncInput.price,
                syncInput.action
            );
        }
    }

    /// @notice returns registrar amount throught Spiritswap router or returns DEI amount when selling registrars
    /// @param syncInput WrapperInput used in synchronizer main contract
    /// @param path path used in Spiritswap router (default path is [0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3])
    function getAmountsOut(
        WrapperViewInput memory syncInput,
        address[] calldata path
    )
        public
        view
        returns (uint256 amountOut)
    {
        if (syncInput.action == 0) {
            uint256 deiAmount = ISynchronizer(synchronizer).getAmountOut(
                syncInput.partnerId,
                syncInput.registrar,
                syncInput.amountIn,
                syncInput.price,
                syncInput.action
            );
            if (path[path.length - 1] != dei) {
                amountOut = IUniswapV2Router02(uniswapRouter).getAmountsOut(deiAmount, path)[path.length - 1];
            } else {
                amountOut = deiAmount;
            }
        } else {
            if (path[0] != dei) {
                syncInput.amountIn = IUniswapV2Router02(uniswapRouter).getAmountsOut(syncInput.amountIn, path)[
                    path.length - 1
                ];
            }
            // buy stock with dei
            amountOut = ISynchronizer(synchronizer).getAmountOut(
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
