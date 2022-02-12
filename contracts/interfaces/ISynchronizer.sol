// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IMuonV02.sol";

interface ISynchronizer {
    event Buy(
        address partnerId,
        address receipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 collateralAmount,
        uint256 feeAmount
    );
    event Sell(
        address partnerId,
        address receipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 collateralAmount,
        uint256 feeAmount
    );
    event WithdrawFee(address platform, uint256 partnerFee, uint256 platformFee, uint256 registrarType);
    event SetMinimumRequiredSignatures(uint256 oldValue, uint256 newValue);
    event SetAppId(uint8 oldId, uint8 newId);
    event SetVirtualReserve(uint256 oldReserve, uint256 newReserve);
    event SetMuonContract(address oldContract, address newContract);
    event ToggleUseVirtualReserve(bool useVirtualReserve);

    function deiContract() external view returns (address);

    function muonContract() external view returns (address);

    function minimumRequiredSignatures() external view returns (uint256);

    function scale() external view returns (uint256);

    function feeCollector(address partner, uint256 registrarType) external view returns (uint256);

    function virtualReserve() external view returns (uint256);

    function appId() external view returns (uint8);

    function useVirtualReserve() external view returns (bool);

    function collatDollarBalance(uint256 collat_usd_price) external view returns (uint256);

    function getChainId() external view returns (uint256);

    function getAmountIn(
        address partnerId,
        address registrar,
        uint256 amountOut,
        uint256 price,
        uint256 action
    ) external view returns (uint256 amountIn);

    function getAmountOut(
        address partnerId,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 action
    ) external view returns (uint256 amountOut);

    function buyFor(
        address partnerId,
        address receipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 expireBlock,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external;

    function sellFor(
        address partnerId,
        address receipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 expireBlock,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external;

    function withdrawFee(address receipient, uint256 registrarType) external;

    function setMinimumRequiredSignatures(uint256 minimumRequiredSignatures_) external;

    function setAppId(uint8 appId_) external;

    function setVirtualReserve(uint256 virtualReserve_) external;

    function setMuonContract(address muonContract_) external;

    function toggleUseVirtualReserve() external;
}

//Dar panah khoda
