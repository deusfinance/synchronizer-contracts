// SPDX-License-Identifier: MIT
pragma solidity ^0.8.10;

interface IConductor {
    function roleChecker() external view returns (address);
	function setRoleChecker(address roleChecker_) external;
	function adminConduct(
		string memory _id,
		string memory shortName,
		string memory shortSymbol,
		string memory longName,
		string memory longSymbol,
		string memory version
	) external returns (address, address);
}
