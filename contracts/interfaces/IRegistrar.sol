// SPDX-License-Identifier: MIT

pragma solidity ^0.8.3;

interface IRegistrar {
    function roleChecker() external view returns (address);
    function version() external view returns (string calldata);
    function registrarType() external view returns (uint256);
    function totalSupply() external view returns (uint256);
    function rename(string memory name, string memory symbol) external;
    function mint(address to, uint256 amount) external;
    function burn(address from, uint256 amount) external;
}
