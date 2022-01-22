const deploySynchronizer = require('./deploy_contracts/deploy_sync.js');
const deployConductor = require('./deploy_contracts/deploy_conductor.js');
const deployRoleChecker = require('./deploy_contracts/deploy_role_checker.js');
const deployRegistrar = require('./deploy_contracts/deploy_registrar.js');

const { verifyAll } = require('./helpers/deploy_contract.js');

async function main() {

    const synchronizer = await deploySynchronizer();

    await new Promise((resolve) => setTimeout(resolve, 30000));
    const roleChecker = await deployRoleChecker();

    await new Promise((resolve) => setTimeout(resolve, 30000));
    await roleChecker.grant(synchronizer.address);

    await new Promise((resolve) => setTimeout(resolve, 30000));
    const conductor = await deployConductor({ 
        roleChecker: roleChecker.address
    });

    // const conductorInstance = await hre.ethers.getContractFactory("Conductor");
    // const conductor = await conductorInstance.attach("0xF7F3280073965e8dfB0b41c8567A5CE59E6bA998");

    // await conductor.adminConduct("TSLA", "Test Tesla short DEUS synthetic", "dTSLA-S", "Test Tesla long DEUS synthetic", "dTSLA", "v1.0.0_beta");    
    // await conductor.adminConduct("BTC", "Test Bitcoin short DEUS synthetic", "dBTC-S", "Test Bitcoin long DEUS synthetic", "dBTC", "v1.0.0_beta")

    await new Promise((resolve) => setTimeout(resolve, 30000));

    await deployRegistrar({
        roleChecker: "0x74Fa4bCB360bB9F483D3b7c822ED9d51BC96c3f7",
        name: "Verified synthetic token",
        symbol: "VST",
        version: "v1.0.0"
    })

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
