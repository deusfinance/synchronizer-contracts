const deploySynchronizer = require('./deploy_contracts/deploy_sync.js');
const deployConductor = require('./deploy_contracts/deploy_conductor.js');
const deployRoleChecker = require('./deploy_contracts/deploy_role_checker.js');
const deployRegistrar = require('./deploy_contracts/deploy_registrar.js');
const deployPartnerManager = require('./deploy_contracts/deploy_partner_manager.js');
const { verifyAll } = require('./helpers/deploy_contract.js');

async function main() {

    // configuration
    const deiAddress = '0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3';
    const muonAddress = '0xE4F8d9A30936a6F8b17a73dC6fEb51a3BBABD51A';
    const platform = '0xE5227F141575DcE74721f4A9bE2D7D636F923044';
    const minimumRequiredSignature = '1';
    const virtualReserve = '5000000000000000000000000';
    const appID = '9';
    const minimumRegistrarFee = ['10000000000000000', '100000000000000000', '3000000000000000'];

    const partnerManager = await deployPartnerManager({
        platform: platform,
        minimumRegistrarFee: minimumRegistrarFee
    });

    await new Promise((resolve) => setTimeout(resolve, 30000));
    const synchronizer = await deploySynchronizer({ 
        deiAddress: deiAddress, 
        muonAddress: muonAddress, 
        partnerManagerAddress: partnerManager.address, 
        minimumRequiredSignature: minimumRequiredSignature,
        virtualReserve: virtualReserve, 
        appID: appID 
    });

    await new Promise((resolve) => setTimeout(resolve, 30000));
    const roleChecker = await deployRoleChecker();

    await new Promise((resolve) => setTimeout(resolve, 30000));
    await roleChecker.grant(synchronizer.address);

    await new Promise((resolve) => setTimeout(resolve, 30000));
    const conductor = await deployConductor({ 
        roleChecker: roleChecker.address
    });

    await new Promise((resolve) => setTimeout(resolve, 30000));
    await conductor.adminConduct("BTC", "Bitcoin reverse synth", "rBTC", "Bitcoin synth", "dBTC", "v1.0", "1");

    await new Promise((resolve) => setTimeout(resolve, 30000));
    await deployRegistrar({
        roleChecker: roleChecker.address,
        name: 'Verified Synthetic token',
        symbol: 'VST',
        version: 'v1.0.0',
        type: '0'
    })

    console.log(deployedContracts);
    for (let i = 0; i < deployedContracts.length; i++) {
        let contract = deployedContracts[i];
        console.log("verifing", contract['address']);
        try {
            await hre.run('verify:verify', contract);
        } catch (error) {
            console.log(error);
        }
    }

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
