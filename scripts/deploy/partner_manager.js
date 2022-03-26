const { deploy } = require("../helpers/deploy_contract")

module.exports = async ({ owner, platformFeeCollector, minPlatformFee, minTotalFee }) => {
  const deployer = process.env.SYNC_DEPLOYER


  const deployedPartnerManager = await deploy({
    deployer: deployer,
    contractName: "PartnerManager",
    constructorArguments: [owner, platformFeeCollector, minPlatformFee, minTotalFee],
  })

  const partnerManagerInstance = await hre.ethers.getContractFactory("PartnerManager")
  return partnerManagerInstance.attach(deployedPartnerManager.address)
}
