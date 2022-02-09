const conductData = require("./data/SP500.json")
const { sleep } = require("../sleep")

async function main() {
  const conductorAddress = "0x3DA90Ea1733d7C579124AA6b31BdeC24c63197DB" // fantom
  const conductorInstance = await hre.ethers.getContractFactory("Conductor")
  const conductor = conductorInstance.attach(conductorAddress)

  for (let i = 50; i < conductData.length; i++) {
    console.log("*", conductData[i].symbol)
    const tx = await conductor.conduct(
      conductData[i].symbol,
      conductData[i].name + " reverse synth",
      "r" + conductData[i].symbol,
      conductData[i].name + " synth",
      "d" + conductData[i].symbol,
      "v1.0",
      "0"
    )
    // console.log(tx)
    await sleep(5000)
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
