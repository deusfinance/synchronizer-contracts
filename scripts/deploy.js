const deploySync = require("./deploy/synchronizer")
const { verifyAll } = require("./helpers/deploy_contract")

async function main() {
  await deploySync()

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
