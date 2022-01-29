const path = require('path');
const envPath = path.join(__dirname, '.env');
require('dotenv').config({ path: envPath });

require('hardhat-deploy');
require('hardhat-contract-sizer');
require("@nomiclabs/hardhat-waffle");
require("@nomiclabs/hardhat-truffle5");
require("@nomiclabs/hardhat-web3");
require("@nomiclabs/hardhat-etherscan");

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async () => {
	const accounts = await ethers.getSigners();

	for (const account of accounts) {
		console.log(account.address);
	}
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
	defaultNetwork: "localhost",
	networks: {
		localhost: {
			url: 'http://127.0.0.1:8545',
			accounts: [
				process.env.SYNC_DEPLOYER_PRIVATE_KEY
			],
		},
		rinkeby: {
			url: `https://rinkeby.infura.io/v3/${process.env.INFURA_PROJECT_ID}`,
			accounts: [
				process.env.SYNC_DEPLOYER_PRIVATE_KEY
			],
			chainId: 4,
			gas: "auto",
			gasPrice: "auto",
			gasMultiplier: 1.2
		},
   		fantom: {
			url: `https://rpc.ftm.tools`,
			accounts: [
				process.env.SYNC_DEPLOYER_PRIVATE_KEY
			],
			chainId: 250,
			gas: "auto",
			gasPrice: 500100000000,	//800.1 Gwei
			gasMultiplier: 1.2
		},
	},
	solidity: {
		compilers: [
			{
				version: "0.6.12",
				settings: {
					optimizer: {
						enabled: true,
						runs: 100000
					}
				}
			},
			{
				version: "0.7.6",
				settings: {
					optimizer: {
						enabled: true,
						runs: 100000
					}
				}
			},
			{
				version: "0.8.11",
				settings: {
					optimizer: {
						enabled: true,
						runs: 100000
					}
				}
			}
		],
	},
	paths: {
		sources: "./contracts",
		tests: "./test",
		cache: "./cache",
		artifacts: "./artifacts"
	},
	mocha: {
		timeout: 360000
	},
	etherscan: {
		apiKey: process.env.FANTOM_API_KEY, // FANTOM Mainnet
		// apiKey: process.env.ETHERSCAN_API_KEY // Eth Mainnet
	},
	contractSizer: {
		alphaSort: true,
		runOnCompile: true,
		disambiguatePaths: false,
	}
};

