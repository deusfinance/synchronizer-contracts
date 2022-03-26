const { deploy } = require("../helpers/deploy_contract")

module.exports = async ({
  mintHelper,
  muonAddress,
  partnerManagerAddress,
  minimumRequiredSignatures,
  expireTime,
  appId,
}) => {
  const deployer = process.env.SYNC_DEPLOYER

  const deployedSynchronizer = await deploy({
    deployer: deployer,
    contractName: "Synchronizer",
    constructorArguments: [
      mintHelper,
      muonAddress,
      partnerManagerAddress,
      minimumRequiredSignatures,
      expireTime,
      appId,
    ],
  })
  const synchronizerInstance = await hre.ethers.getContractFactory("Synchronizer")
  return synchronizerInstance.attach(deployedSynchronizer.address)
}
