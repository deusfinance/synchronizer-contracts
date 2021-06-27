require("@nomiclabs/hardhat-waffle");
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
  solidity: "0.8.3",
  etherscan: {
    // Your API key for Etherscan
    // Obtain one at https://etherscan.io/
    apiKey: "5NW8HAEN32EUCCPIVJS15IEADD1N2JX81W" // HECO
    // apiKey: "5QVMRVDSUIVN4ZJDGSNFEQCHISRN9XMUDH" // Polygon
  },
  networks: {
    rinkeby: {
      url:'https://rinkeby.infura.io/v3/e316f17379174e849af4e39f65ba1fef',
      accounts: ["0xde87297af813a88a68189f8c3165aeb760708f71453451fb2aacaf3d16524f92"]
    },    
    heco: {
      url: "https://http-mainnet-node.huobichain.com/",
      accounts: ["0xde87297af813a88a68189f8c3165aeb760708f71453451fb2aacaf3d16524f92"]
    },
    polygon: {
      url: "https://rpc-mainnet.matic.network",
      accounts: ["0xde87297af813a88a68189f8c3165aeb760708f71453451fb2aacaf3d16524f92"]
    }
  },
};

