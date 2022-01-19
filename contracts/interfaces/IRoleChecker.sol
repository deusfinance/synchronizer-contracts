// SPDX-License-Identifier: MIT
pragma solidity ^0.8.3;

interface IRoleChecker {
    function verify(address caller) external returns (bool);
    function grant(address user) external;
    function revoke(address user) external;
}
