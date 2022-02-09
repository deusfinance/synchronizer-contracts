// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IConductor {
    event Conducted(string _id, address registrar, string name, string symbol, string version, uint256 registrarType);

    function roleChecker() external view returns (address);

    function setRoleChecker(address roleChecker_) external;

    function conduct(
        string memory _id,
        string memory shortName,
        string memory shortSymbol,
        string memory longName,
        string memory longSymbol,
        string memory version,
        uint256 registrarType
    ) external returns (address, address);
}
