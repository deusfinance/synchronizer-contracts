const deploySynchronizer = require('./deploy_contracts/deploy_sync.js');
const deployConductor = require('./deploy_contracts/deploy_conductor.js');
const deployRoleChecker = require('./deploy_contracts/deploy_role_checker.js');
const deployRegistrar = require('./deploy_contracts/deploy_registrar.js');
const deployPartnerManager = require('./deploy_contracts/deploy_partner_manager.js');
const { verifyAll } = require('./helpers/deploy_contract.js');

async function main() {

    // configuration
    const deiAddress = '0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3';
    const muonAddress = '0xeE67E903d322FA65d8D370dE4eD99Fd9C3C5EF54'; // muon testnet
    const platform = '0xE5227F141575DcE74721f4A9bE2D7D636F923044';
    const minimumRequiredSignature = '1';
    const virtualReserve = '5000000000000000000000000';
    const appID = '9';
    const minimumRegistrarFee = ['1000000000000000', '10000000000000000', '300000000000000'];

    const partnerManager = await deployPartnerManager({
        platform: platform,
        minimumRegistrarFee: minimumRegistrarFee
    });

    // await partnerManager.addPartner('0x1164fe7a76D22EAA66f6A0aDcE3E3a30d9957A5f', '2000000000000000', '1000000000000000', '200000000000000');

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

    // await new Promise((resolve) => setTimeout(resolve, 30000));
    // await deployRegistrar({
    //     roleChecker: roleChecker.address,
    //     name: 'Verified Synthetic token',
    //     symbol: 'VST',
    //     version: 'v1.0.0',
    //     type: '0'
    // })

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
