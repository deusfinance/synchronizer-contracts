const { deploy } = require("../helpers/deploy_contract.js");

module.exports = async ( { roleChecker } ) => {
    const deployer = process.env.SYNC_DEPLOYER;
  
    const deployedConductor = await deploy({
        deployer: deployer,
        contractName: 'Conductor',
        constructorArguments: [roleChecker]
    })
    const conductorInstance = await hre.ethers.getContractFactory("Conductor");
    return conductorInstance.attach(deployedConductor.address);
}