const { deploy } = require("../helpers/deploy_contract.js");

module.exports = async () => {
    const deployer = process.env.SYNC_DEPLOYER;
  
    const deployedSync = await deploy({
        deployer: deployer,
        contractName: 'Synchronizer',
        constructorArguments: ["2", "5000000000000000000000000", "0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3"]
    })
    const syncInstance = await hre.ethers.getContractFactory("Synchronizer");
    return syncInstance.attach(deployedSync.address);
}