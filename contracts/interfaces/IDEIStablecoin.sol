// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.10;

interface IDEIStablecoin {
    function pool_burn_from(address b_address, uint256 b_amount) external;
    function pool_mint(address m_address, uint256 m_amount) external;
    function global_collateral_ratio() external view returns (uint256);
}
