const conductData = require("../data/SP500.json")
const { sleep } = require("./sleep")
const { constructName, constructSymbol, constructVersion } = require("./naming")

async function main() {
  const conductorAddress = "0x570D710d9F20599551246EC24D8A8cCffeb57Ccf" // fantom
  const conductorInstance = await hre.ethers.getContractFactory("Conductor")
  const conductor = conductorInstance.attach(conductorAddress)

  for (let i = 484; i < conductData.length; i++) {
    console.log("*", conductData[i].symbol)
    const tx = await conductor.conduct(
      conductData[i].symbol,
      constructName(conductData[i].name, "SHORT"),
      constructSymbol(conductData[i].symbol, "SHORT"),
      constructName(conductData[i].name, "LONG"),
      constructSymbol(conductData[i].symbol, "LONG"),
      constructVersion(1, 0),
      "0"
    )
    // console.log(tx)
    await sleep(10000)
  }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
