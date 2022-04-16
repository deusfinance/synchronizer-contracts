const deploySynchronizer = require("./deploy/synchronizer")
const deployPartnerManager = require("./deploy/partner_manager")
const { verifyAll } = require("./helpers/deploy_contract")
const { sleep } = require("./helpers/sleep")

async function main() {
  // configuration
  const mintHelperAddress = "0x1B7879F4dB7980E464d6B92FDbf9DaA8F1E55073"
  const muonAddress = "0xE4F8d9A30936a6F8b17a73dC6fEb51a3BBABD51A"
  const platform = "0xEf6b0872CfDF881Cf9Fe0918D3FA979c616AF983"
  const owner = "0xE5227F141575DcE74721f4A9bE2D7D636F923044"
  const minimumRequiredSignatures = "1"
  const expireTime = 45
  const appId = "9"
  const minPlatformFee = ["1000000000000000", "3340000000000000", "1000000000000000", "1000000000000000"]
  const minTotalFee = ["3000000000000000", "10000000000000000", "3000000000000000", "3000000000000000"]
  const delayTimestamp = 50

  // const partnerManager = await deployPartnerManager({
  //   owner: owner,
  //   platformFeeCollector: platform,
  //   minPlatformFee: minPlatformFee, 
  //   minTotalFee: minTotalFee 
  // })

  await sleep(20000)
  const synchronizer = await deploySynchronizer({
    owner: owner,
    mintHelper: mintHelperAddress,
    muonAddress: muonAddress,
    // partnerManagerAddress: partnerManager.address,
    partnerManagerAddress: "0xA1b701D07cc1566e3f07D8c273654CDeA9dad4a0",
    minimumRequiredSignatures: minimumRequiredSignatures,
    expireTime: expireTime,
    delayTimestamp: delayTimestamp,
    appId: appId,
  })

  const roleCheckerInstance = await hre.ethers.getContractFactory("RoleChecker")
  const roleChecker = roleCheckerInstance.attach("0x8e6F8844B73DAe005B02fd8776eE4719E7d5Eb01")

  await sleep(20000)
  // await roleChecker.revoke("0x55d0740ec1535F5714435e739Ca55547c9f46047")
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
