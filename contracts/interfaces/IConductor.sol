// SPDX-License-Identifier: MIT

pragma solidity ^0.8.10;

interface IConductor {
    event Conducted(string _id, address short, address long);
    event Liquidated(address liquidatedRegistrar, address newRegistrar);

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
