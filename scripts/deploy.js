// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy

  const Contract = await hre.ethers.getContractFactory("Registrar");
  // const contract = await Contract.deploy("0xe82aa18b107aaf8D3829111C91CD0D133E0773DC", "0x4BED4d66B1a17855d60B3cba81905d16d645A817", "0x3Bc92ff6f52264ca600CA5F2f3A19535f7BDdf87");
  const contract = await Contract.deploy("0x72e4c625995286E86b11435e13404D5210978A7E", "0x72e4c625995286E86b11435e13404D5210978A7E", "0x72e4c625995286E86b11435e13404D5210978A7E", "Name", "NME");


  await contract.deployed();

  console.log("Conductor deployed to:", contract.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
