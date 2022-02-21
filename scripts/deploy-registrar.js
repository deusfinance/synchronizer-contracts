const { sleep } = require("./helpers/sleep")
const { constructName, constructSymbol, constructVersion } = require("./helpers/naming")

async function main() {
  const conductorAddress = "0x570D710d9F20599551246EC24D8A8cCffeb57Ccf" // fantom
  const conductorInstance = await hre.ethers.getContractFactory("Conductor")
  const conductor = conductorInstance.attach(conductorAddress)

  token = {
    name: 'GameStop Corp.',
    symbol: 'GME'
  }

  const tx = await conductor.conduct(
    token.symbol,
    constructName(token.name, "SHORT"),
    constructSymbol(token.symbol, "SHORT"),
    constructName(token.name, "LONG"),
    constructSymbol(token.symbol, "LONG"),
    constructVersion(1, 0),
    "0"
  )
  // console.log(tx)
  // await sleep(10000)
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
