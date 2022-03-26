// SPDX-License-Identifier: GPL3.0-or-later

pragma solidity 0.8.13;

interface IMintHelper {
    function dei() external view returns (address);

    function useVirtualReserve(address pool) external view returns (bool);

    function virtualReserve() external view returns (uint256);

    function MINTER_ROLE() external view returns (bytes32);

    function mint(address recv, uint256 amount) external;

    function burnFrom(address from, uint256 amount) external;

    function collatDollarBalance(uint256 collat_usd_price)
        external
        view
        returns (uint256);

    function setVirtualReserve(uint256 virtualReserve_) external;

    function setUseVirtualReserve(address pool, bool state) external;
}