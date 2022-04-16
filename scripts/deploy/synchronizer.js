const { deploy } = require("../helpers/deploy_contract")

module.exports = async ({
  owner,
  mintHelper,
  muonAddress,
  partnerManagerAddress,
  minimumRequiredSignatures,
  expireTime,
  delayTimestamp,
  appId,
}) => {
  const deployer = process.env.SYNC_DEPLOYER

  const deployedSynchronizer = await deploy({
    deployer: deployer,
    contractName: "Synchronizer",
    constructorArguments: [
      owner,
      mintHelper,
      muonAddress,
      partnerManagerAddress,
      minimumRequiredSignatures,
      expireTime,
      delayTimestamp,
      appId,
    ],
  })
  const synchronizerInstance = await hre.ethers.getContractFactory("Synchronizer")
  return synchronizerInstance.attach(deployedSynchronizer.address)
}
