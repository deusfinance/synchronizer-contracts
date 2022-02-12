const { deploy } = require("../helpers/deploy_contract")

module.exports = async ({
  deiAddress,
  muonAddress,
  partnerManagerAddress,
  minimumRequiredSignatures,
  virtualReserve,
  appId,
}) => {
  const deployer = process.env.SYNC_DEPLOYER

  const deployedSynchronizer = await deploy({
    deployer: deployer,
    contractName: "Synchronizer",
    constructorArguments: [
      deiAddress,
      muonAddress,
      partnerManagerAddress,
      minimumRequiredSignatures,
      virtualReserve,
      appId,
    ],
  })
  const synchronizerInstance = await hre.ethers.getContractFactory("Synchronizer")
  return synchronizerInstance.attach(deployedSynchronizer.address)
}
