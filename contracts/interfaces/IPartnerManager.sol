// SPDX-License-Identifier: MIT
pragma solidity ^0.8.11;

interface IPartnerManager {

    event PartnerAdded(address owner, uint256 share, uint256[] registrarTradingFee);

    function platform() external view returns (address);
    function minimumRegistrarFee(uint256 index) external view returns (uint256);
    function scale() external view returns (uint256);
    function isPartner(address partner) external view returns (bool);
    function partnerShare(address partner) external view returns (uint256);
    function partnerTradingFee(address partner, uint256 index) external view returns (uint256);
    function addPartner(
        address owner,
        uint256 share,
        uint256[] memory registrarTradingFee
    ) external;
}