const deploySynchronizer = require("./deploy/synchronizer")
const deployPartnerManager = require("./deploy/partner_manager")
const { verifyAll } = require("./helpers/deploy_contract")
const { sleep } = require("./helpers/sleep")

async function main() {
  // configuration
  const mintHelperAddress = "0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3"
  const muonAddress = "0xE4F8d9A30936a6F8b17a73dC6fEb51a3BBABD51A"
  const platform = "0xEf6b0872CfDF881Cf9Fe0918D3FA979c616AF983"
  const owner = "0xE5227F141575DcE74721f4A9bE2D7D636F923044"
  const minimumRequiredSignatures = "1"
  const expireTime = 30;
  const appId = "9"
  const minPlatformFee = ["". "", "", ""]
  const minTotalFee = ["". "", "", ""]

  const partnerManager = await deployPartnerManager({
    owner: owner,
    platformFeeCollector: platform,
    minPlatformFee: minPlatformFee, 
    minTotalFee: minTotalFee 
  })

  await sleep(20000)
  const synchronizer = await deploySynchronizer({
    mintHelper: mintHelperAddress,
    muonAddress: muonAddress,
    partnerManagerAddress: partnerManager.address,
    minimumRequiredSignatures: minimumRequiredSignatures,
    expireTime: expireTime,
    appId: appId,
  })

  const roleCheckerInstance = await hre.ethers.getContractFactory("RoleChecker")
  const roleChecker = roleCheckerInstance.attach("0x8e6F8844B73DAe005B02fd8776eE4719E7d5Eb01")

  await sleep(20000)
  await roleChecker.grant(synchronizer.address)
  await verifyAll()
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
