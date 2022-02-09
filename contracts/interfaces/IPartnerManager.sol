// SPDX-License-Identifier: MIT

pragma solidity ^0.8.11;

interface IPartnerManager {
    event PartnerAdded(address owner, uint256[3] partnerFee);

    function platformFee(uint256 index) external view returns (uint256);
    function partnerFee(address partner, uint256 index) external view returns (uint256);
    function platform() external view returns (address);
    function scale() external view returns (uint256);
    function isPartner(address partner) external view returns (bool);

    function addPartner(
        address owner,
        uint256 stockFee,
        uint256 cryptoFee,
        uint256 forexFee
    ) external;
}