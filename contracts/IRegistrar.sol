// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IRegistrar {
	function totalSupply() external view returns (uint256);
	function mint(address to, uint256 amount) external;
	function burn(address from, uint256 amount) external;
}
