const deploySynchronizer = require('./deploy_contracts/deploy_sync.js');
const deployConductor = require('./deploy_contracts/deploy_conductor.js');
const deployRoleChecker = require('./deploy_contracts/deploy_role_checker.js');

const { verifyAll } = require('./helpers/deploy_contract.js');

async function main() {

    await deploySynchronizer();

    const roleChecker = await deployRoleChecker();

    const conductor = await deployConductor({ 
        roleChecker: roleChecker.address
    });

    await conductor.adminConduct("TSLA", "Tesla short DEUS synthetic", "dTSLA-S", "Tesla long DEUS synthetic", "dTSLA", "v1.0.0");    

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
