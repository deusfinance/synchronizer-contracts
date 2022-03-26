// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IPartnerManager {
    event RegistrarFeeAdded(address owner, uint256[] registrarType, uint256[] partnerFee);
    event PlatformFeeAdded(uint256[] registrarType, uint256[] minPlatformFee, uint256[] minTotalFee);
    event SetCap(address partnerId, int256 cap);

    function minPlatformFee(uint256 index) external view returns (uint256);

    function minTotalFee(uint256 index) external view returns (uint256);

    function partnerFee(address partner, uint256 index) external view returns (uint256);

    function platformFeeCollector() external view returns (address);

    function scale() external view returns (uint256);

    function isPartner(address partner) external view returns (bool);

    function maxCap(address partner) external view returns (int256);

    function addRegistrarFee(uint256[] memory registrarType, uint256[] memory partnerFee_) external;

    function addPlatformFee(
        uint256[] memory registrarType,
        uint256[] memory minPlatformFee_,
        uint256[] memory minTotalFee_
    ) external;
}
