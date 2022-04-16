// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IMuonV02.sol";

interface ISynchronizer {
    event Buy(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 collateralAmount,
        uint256 feeAmount
    );
    event Sell(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 collateralAmount,
        uint256 feeAmount
    );
    event WithdrawFee(address partner, uint256 partnerFee, uint256 platformFee, uint256 registrarType);
    event SetMinimumRequiredSignatures(uint256 oldValue, uint256 newValue);
    event SetAppId(uint32 oldId, uint32 newId);
    event SetVirtualReserve(uint256 oldReserve, uint256 newReserve);
    event SetMuonContract(address oldContract, address newContract);
    event ToggleUseVirtualReserve(bool useVirtualReserve);
    event SetExpireTime(uint256 oldExpireTime, uint256 newExpireTime);
    event SetDelayTimestamp(uint256 oldDelayTimestamp, uint256 newDelayTimestamp);
    event SetMintHelper(address oldMintHelper, address newMintHelper);
    event Collect(address user, uint256 amount);

    function version() external view returns (string memory);

    function mintHelper() external view returns (address);

    function muonContract() external view returns (address);

    function deiContract() external view returns (address);

    function partnerManager() external view returns (address);

    function minimumRequiredSignatures() external view returns (uint256);

    function scale() external view returns (uint256);

    function delayTimestamp() external view returns (uint256);

    function expireTime() external view returns (uint256);

    function feeCollector(address partner, uint256 registrarType) external view returns (uint256);

    function balance(address user) external view returns (uint256);

    function cap(address partner) external view returns (int256);

    function lastTrade(address partner) external view returns (uint256);

    function appId() external view returns (uint32);

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
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 expireBlock,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external returns (uint256 registrarAmount);

    function sellFor(
        address partnerId,
        address recipient,
        address registrar,
        uint256 amountIn,
        uint256 price,
        uint256 expireBlock,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external returns (uint256 deiAmount);

    function collect() external;

    function withdrawFee(address recipient, uint256 registrarType) external;

    function setMinimumRequiredSignatures(uint256 minimumRequiredSignatures_) external;

    function setAppId(uint32 appId_) external;

    function setMuonContract(address muonContract_) external;

    function setExpireTime(uint256 expireTime_) external;

    function setDelayTimestamp(uint256 delayTimestamp_) external;

    function setMintHelper(address mintHelper_) external;
}

//Dar panah khoda
