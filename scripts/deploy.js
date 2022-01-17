const deploySync = require('./deploy_contracts/deploy_sync.js');

const { verifyAll } = require('./helpers/deploy_contract.js');

async function main() {

    await deploySync();

    await verifyAll();
}


// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch(error => {
        console.error(error);
        process.exit(1);
    });
