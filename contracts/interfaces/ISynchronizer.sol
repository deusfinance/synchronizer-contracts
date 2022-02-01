// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

import "./IMuonV02.sol";

interface ISynchronizer {

    event Buy(address partnerID, address user, address registrar, uint256 deiAmount, uint256 price, uint256 collateralAmount, uint256 feeAmount);
    event Sell(address partnerID, address user, address registrar, uint256 registrarAmount, uint256 price, uint256 collateralAmount, uint256 feeAmount);
    event WithdrawFee(address platform, uint256 partnerFee, uint256 platformFee);
    event MinimumRequiredSignatureSet(uint256 oldValue, uint256 newValue);
    event AppIdSet(uint8 oldID, uint8 newID);
    event VirtualReserveSet(uint256 oldReserve, uint256 newReserve);
    event MuonContractSet(address oldContract, address newContract);
    event UseVirtualReserveToggled(bool useVirtualReserve);

    function muonContract() external view returns (address);
    function deiContract() external view returns (address);
    function minimumRequiredSignature() external view returns (uint256);
    function scale() external view returns (uint256);
    function trades(address partner) external view returns (uint256);
    function virtualReserve() external view returns (uint256);
    function appID() external view returns (uint8);
    function useVirtualReserve() external view returns (bool);
    function collatDollarBalance(uint256 collat_usd_price)
        external
        view
        returns (uint256);
    function getChainID() external view returns (uint256);
    function getAmountIn(
        address partnerID,
        address registrar, 
        uint256 amountOut,
        uint256 price,
        uint256 action
    ) external view returns (uint256 amountIn);
    function getAmountOut(
        address partnerID, 
        address registrar, 
        uint256 amountIn,
        uint256 price,
        uint256 action
    ) external view returns (uint256 amountOut);
    function sellFor(
        address partnerID,
        address _user,
        address registrar,
        uint256 amountIn,
        uint256 expireBlock,
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external;
    function buyFor(
        address partnerID,
        address _user,
        address registrar,
        uint256 amountIn,
        uint256 expireBlock,
        uint256 price,
        bytes calldata _reqId,
        SchnorrSign[] calldata sigs
    ) external;
    function withdrawFee() external;
    function setMinimumRequiredSignature(uint256 minimumRequiredSignature_) external;
    function setAppId(uint8 appID_) external;
    function setVirtualReserve(uint256 virtualReserve_) external;
    function setMuonContract(address muonContract_) external;
    function toggleUseVirtualReserve() external;
}

//Dar panah khoda
