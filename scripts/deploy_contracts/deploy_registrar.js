const { deploy } = require("../helpers/deploy_contract.js");

module.exports = async ( { roleChecker, name, symbol, version, type } ) => {
    const deployer = process.env.SYNC_DEPLOYER;
  
    const deployedRegistrar = await deploy({
        deployer: deployer,
        contractName: 'Registrar',
        constructorArguments: [roleChecker, name, symbol, version, type]
    })
    const registrarInstance = await hre.ethers.getContractFactory('Registrar');
    return registrarInstance.attach(deployedRegistrar.address);
}