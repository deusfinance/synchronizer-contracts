// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.

const deploySync = require('../deploy_contracts/deploy_sync');
const deployDei = require('deus-core/scripts/deploy_contracts/deploy_dei');
const { printSuccess, addTestCase, printTestCasesResults, sleep } = require('./utils');
const Muon = require('./muon');
const { impersonate, transfer, getBalanceOf, setBalance, } = require('../helpers/modify_chain');
const hre = require("hardhat");
// const deploy_dei = require('deus-core/scripts/deploy_contracts/deploy_dei');

async function main() {
    testCases = [];

    const tokenId = "0x57E99744122Fa3804ACF3bF21c404a6e7fd6f8f7";
    const syncDeployer = process.env.SYNC_DEPLOYER;
    setBalance(syncDeployer);
    const mainDeployer = process.env.MAIN_DEPLOYER;
    setBalance(mainDeployer);
    app_id = 9;
    muon_address = '0xE4F8d9A30936a6F8b17a73dC6fEb51a3BBABD51A';

    const mainSigner = await impersonate(mainDeployer);
    const dei = await deployDei(mainSigner);

    // const deiTrustyAddress = "0xE5227F141575DcE74721f4A9bE2D7D636F923044";
    // const deiAddress = "0xDE12c7959E1a72bbe8a5f7A1dc8f8EeF9Ab011B3";
    // const deiTrustySigner = await impersonate(deiTrustyAddress);
    // const dei = (await hre.ethers.getContractFactory("DEIStablecoin", deiTrustySigner)).attach(deiAddress);
    try {

        await dei.addPool(mainDeployer);
    }
    catch (error) {
        console.log(error);
    }
    await dei.pool_mint(syncDeployer, BigInt(10e18));
    console.log(BigInt(await dei.balanceOf(mainDeployer)));



    const roleCheckerOwner = '0xB02648091da9e0AAcdd9F5cB9080C4893cad6C4E';
    setBalance(roleCheckerOwner);
    const roleCheckerAddress = '0xE36bFaA446530c166f175671a6f22687699Dc7dc';
    const roleCheckerSigner = await impersonate(roleCheckerOwner);
    const roleChecker = (await hre.ethers.getContractFactory("RoleChecker", roleCheckerSigner)).attach(roleCheckerAddress);

    const syncDeployerSigner = await impersonate(syncDeployer);
    const sync = await deploySync(dei.address, syncDeployerSigner);
    const deiWithSync = (await hre.ethers.getContractFactory("DEIStablecoin", syncDeployerSigner)).attach(dei.address);
    await roleChecker.grant(sync.address);
    await dei.addPool(sync.address);


    await sync.setMuonContract(muon_address);
    await sync.setAppId(app_id);

    const muon = new Muon("https://node-balancer.muon.net/v1/");

    muonResult = await muon
        .app("synchronizer")
        .method("signature", {
            tokenId: tokenId,
            action: "buy",
            chain: "rinkeby",
            multiplier: "1",
        }).call();

    console.log(muonResult);
    // if (muonResult.data == undefined)

    //     muonResult = {
    //         confirmed: true,
    //         _id: '61f6950b0189745a2952b20f',
    //         app: 'synchronizer',
    //         method: 'signature',
    //         nSign: 4,
    //         owner: '0x60AA825FffaF4AC68392D886Cc2EcBCBa3Df4BD9',
    //         peerId: 'QmTLpbUrFJap7FNQhUo8RqRCXSDhdKjXmXAyCpNCd8YtMm',
    //         data: {
    //             params: {
    //                 tokenId: '0x57E99744122Fa3804ACF3bF21c404a6e7fd6f8f7',
    //                 action: 'buy',
    //                 chain: 'rinkeby',
    //                 multiplier: '1'
    //             },
    //             timestamp: 1643549963,
    //             init: {
    //                 party: 'P16415418721872448934',
    //                 nonce: 'K16435499637961619207',
    //                 nonceAddress: '0xe5B158C0ab1B202975362CCc740C35F72000f0CA'
    //             },
    //             result: {
    //                 multiplier: '1',
    //                 price: '37922470000000004784128',
    //                 fee: 10000000000000000,
    //                 address: '0x57E99744122Fa3804ACF3bF21c404a6e7fd6f8f7',
    //                 blockNumber: 14107466,
    //                 action: 'buy',
    //                 chain: 'rinkeby'
    //             }
    //         },
    //         startedAt: 1643549963,
    //         confirmedAt: 1643549968,
    //         signatures: [
    //             {
    //                 owner: '0xF096EC73cB49B024f1D93eFe893E38337E7a099a',
    //                 ownerPubKey: [Object],
    //                 timestamp: 1643549968,
    //                 result: [Object],
    //                 signature: '0x60e095dea659642010f1665e1b48c3f64888fd4c96fe07bd378d7ecefa1f8770'
    //             }
    //         ],
    //         cid: 'f01701220a80997c344c99545fac02861d4816c9d99c1aa71fc99cb5a305fe44d15d74a23',
    //         reqId: '0x01701220a80997c344c99545fac02861d4816c9d99c1aa71fc99cb5a305fe44d15d74a23',
    //         sigs: [
    //             {
    //                 signature: '0x60e095dea659642010f1665e1b48c3f64888fd4c96fe07bd378d7ecefa1f8770',
    //                 owner: '0xF096EC73cB49B024f1D93eFe893E38337E7a099a',
    //                 nonce: '0xe5B158C0ab1B202975362CCc740C35F72000f0CA'
    //             }
    //         ]
    //     };
    console.log(BigInt(muonResult.data.result.price));
    const amountIn = 1000000;
    await deiWithSync.approve(sync.address, amountIn);
    await sync.buyFor(
        mainDeployer,
        tokenId,
        amountIn,
        BigInt(muonResult.data.result.fee),
        muonResult.data.result.blockNumber,
        BigInt(muonResult.data.result.price),
        muonResult.reqId,
        [[BigInt(muonResult.sigs[0].signature), muonResult.sigs[0].owner, muonResult.sigs[0].nonce]]
    );


    printTestCasesResults(testCases);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });  
