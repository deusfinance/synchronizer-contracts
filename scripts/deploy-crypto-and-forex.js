const { constructName, constructSymbol, constructVersion } = require("./helpers/naming")

async function main() {
  // configuration
  const conductorAddress = "0x570D710d9F20599551246EC24D8A8cCffeb57Ccf" // fantom
  const conductorInstance = await hre.ethers.getContractFactory("Conductor")
  const conductor = conductorInstance.attach(conductorAddress)

  await conductor.conduct(
    "BTC",
    constructName('Bitcoin', "SHORT"),
    constructSymbol('BTC', "SHORT"),
    constructName("Bitcoin", "LONG"),
    constructSymbol("BTC", "LONG"),
    constructVersion(1, 0),
    "1"
  )

  await conductor.conduct(
    "XAU",
    constructName('Gold', "SHORT"),
    constructSymbol('XAU', "SHORT"),
    constructName("Gold", "LONG"),
    constructSymbol("XAU", "LONG"),
    constructVersion(1, 0),
    "2"
  )
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
