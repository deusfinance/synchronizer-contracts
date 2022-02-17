// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IDEIProxy {
    struct ProxyInput {
        uint256 amountIn;
        uint256 minAmountOut;
        uint256 deusPriceUSD;
        uint256 colPriceUSD;
        uint256 usdcForMintAmount;
        uint256 deusNeededAmount;
        uint256 expireBlock;
        bytes[] sigs;
    }

    function getAmountsOut(
        uint256 amountIn,
        uint256 deusPriceUSD,
        uint256 colPriceUSD,
        address[] calldata path
    )
        external
        view
        returns (
            uint256 amountOut,
            uint256 usdcForMintAmount,
            uint256 deusNeededAmount
        );

    function USDC2DEI(ProxyInput memory proxyInput) external returns (uint256 deiAmount);

    function ERC202DEI(ProxyInput memory proxyInput, address[] memory path) external returns (uint256 deiAmount);

    function Nativecoin2DEI(ProxyInput memory proxyInput, address[] memory path)
        external
        payable
        returns (uint256 deiAmount);
}
