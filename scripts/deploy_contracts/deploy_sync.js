const { deploy } = require("../helpers/deploy_contract.js");

module.exports = async ( { deiAddress, muonAddress, partnerManagerAddress, minimumRequiredSignature, virtualReserve, appID } ) => {
    const deployer = process.env.SYNC_DEPLOYER;
  
    const deployedSynchronizer = await deploy({
        deployer: deployer,
        contractName: 'Synchronizer',
        constructorArguments: [deiAddress, muonAddress, partnerManagerAddress, minimumRequiredSignature, virtualReserve, appID]
    })
    const synchronizerInstance = await hre.ethers.getContractFactory('Synchronizer');
    return synchronizerInstance.attach(deployedSynchronizer.address);
}
