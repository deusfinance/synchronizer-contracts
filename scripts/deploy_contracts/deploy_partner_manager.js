const { deploy } = require("../helpers/deploy_contract.js");

module.exports = async ( { platform, minimumRegistrarFee } ) => {
    const deployer = process.env.SYNC_DEPLOYER;

    const deployedPartnerManager = await deploy({
        deployer: deployer,
        contractName: 'PartnerManager',
        constructorArguments: [platform, minimumRegistrarFee]
    })

    const partnerManagerInstance = await hre.ethers.getContractFactory('PartnerManager');
    return partnerManagerInstance.attach(deployedPartnerManager.address);
}
