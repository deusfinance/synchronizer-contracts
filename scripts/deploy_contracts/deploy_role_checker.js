const { deploy } = require("../helpers/deploy_contract.js");

module.exports = async () => {
    const deployer = process.env.SYNC_DEPLOYER;
  
    const deployedRoleChecker = await deploy({
        deployer: deployer,
        contractName: 'RoleChecker',
        constructorArguments: []
    })
    const roleCheckerInstance = await hre.ethers.getContractFactory("RoleChecker");
    return roleCheckerInstance.attach(deployedRoleChecker.address);
}