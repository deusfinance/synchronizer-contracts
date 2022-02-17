// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;
pragma abicoder v2;

import "./IMuonV02.sol";
import "./IDEIProxy.sol";

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

interface ISynchronizerWrapper {
    function uniswapRouter() external view returns (address);

    function dei() external view returns (address);

    function usdc() external view returns (address);

    function deiProxy() external view returns (address);

    function synchronizer() external view returns (address);

    function deadline() external view returns (uint256);

    function sell(
        uint256 amountIn,
        WrapperInput memory input,
        uint256 minAmountOut,
        address[] calldata path
    ) external;

    function buyWithMinting(
        WrapperInput memory input,
        IDEIProxy.ProxyInput memory proxyInput,
        uint256 minAmountOut,
        address[] calldata path
    ) external;

    function buy(
        uint256 amountIn,
        WrapperInput memory input,
        uint256 minAmountOut,
        address[] calldata path
    ) external;

    function buyWithMintingFromETH(
        WrapperInput memory input,
        IDEIProxy.ProxyInput memory proxyInput,
        uint256 minAmountOut,
        address[] calldata path
    ) external payable;

    function buyWithETH(
        WrapperInput memory input,
        uint256 minAmountOut,
        address[] calldata path
    ) external payable;

    function getAmountsOutWithMinting(
        WrapperViewInput memory syncInput,
        uint256 deusPriceUSD,
        uint256 collateralPrice,
        address[] calldata path
    )
        external
        view
        returns (
            uint256 amountOut,
            uint256 usdcForMintAmount,
            uint256 deusNeededAmount
        );

    function getAmountsOut(WrapperViewInput memory syncInput, address[] calldata path)
        external
        view
        returns (uint256 amountOut);
}

// Dar panahe Khoda
