const deploySynchronizer = require("./deploy/synchronizer")
const deployConductor = require("./deploy/conductor")
const deployRoleChecker = require("./deploy/role_checker")
const deployRegistrar = require("./deploy/registrar")
const deployPartnerManager = require("./deploy/partner_manager")
const { verifyAll } = require("./helpers/deploy_contract")
const { sleep } = require("./helpers/sleep")
const { constructName, constructSymbol, constructVersion } = require("./helpers/naming")

async function main() {
  // configuration
  const deiAddress = "0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3"
  const muonAddress = "0xE4F8d9A30936a6F8b17a73dC6fEb51a3BBABD51A"
  const platform = "0xEf6b0872CfDF881Cf9Fe0918D3FA979c616AF983"
  const minimumRequiredSignatures = "1"
  const virtualReserve = "5000000000000000000000000"
  const appId = "9"
  const minimumRegistrarFee = []

  const partnerManager = await deployPartnerManager({
    platform: platform,
    minimumRegistrarFee: minimumRegistrarFee,
  })

  await sleep(30000)
  const synchronizer = await deploySynchronizer({
    deiAddress: deiAddress,
    muonAddress: muonAddress,
    partnerManagerAddress: partnerManager.address,
    minimumRequiredSignatures: minimumRequiredSignatures,
    virtualReserve: virtualReserve,
    appId: appId,
  })

  const roleCheckerInstance = await hre.ethers.getContractFactory("RoleChecker")
  const roleChecker = roleCheckerInstance.attach("0x8e6F8844B73DAe005B02fd8776eE4719E7d5Eb01")

  await sleep(30000)
  await roleChecker.grant(synchronizer.address)
//   await sleep(30000)
//   await roleChecker.revoke()
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
