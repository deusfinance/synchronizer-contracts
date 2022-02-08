const conductData = require('./helpers/s-and-p-500.json'); 
const { verifyAll } = require('./helpers/deploy_contract.js');

async function main() {

    // configuration
    const conductorAddress = "0x3DA90Ea1733d7C579124AA6b31BdeC24c63197DB";  // fantom

    const conductorInstance = await hre.ethers.getContractFactory("Conductor");
    const conductor =  conductorInstance.attach(conductorAddress);

    for(let i = 50; i < conductData.length; i++) {
        console.log("*", conductData[i].Symbol)
        const tx = await conductor.conduct(conductData[i].Symbol, conductData[i].Name+" reverse synth", "r"+conductData[i].Symbol, conductData[i].Name+" synth", "d"+conductData[i].Symbol, "v1.0", "0");
        // console.log(tx)
        await new Promise((resolve) => setTimeout(resolve, 5000));
    }
    
    
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
