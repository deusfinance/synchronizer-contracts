const path = require('path');
const envPath = path.join(__dirname, './.env');
require('dotenv').config({ path: envPath });

async function sleep(miliseconds) {
    if (!process.env.LOCAL){
        new Promise((resolve) => setTimeout(resolve, miliseconds));
    }
}

function assert(condition, message) {
    if (!condition) {
        throw "\x1b[31m" + message + "\x1b[0m" || "Assertion failed";
    }
}

function printSuccess(message) {
    console.log("\x1b[32m" + message + "\x1b[0m");
}

function getRandomAddress() {
    return '0x' + [...Array(40)].map(() => Math.floor(Math.random() * 16).toString(16)).join('');
}

async function oracleServerSign(deusAddress, deusPrice, deiAddress, deiPrice, expireBlock, chainId) {
    let encodedAbi = hre.web3.eth.abi.encodeParameters(
        ['address', 'uint256', 'address', 'uint256', 'uint256', 'uint256'],
        [deusAddress, deusPrice, deiAddress, deiPrice, expireBlock, chainId]
    );

    encodedAbi = encodedAbi.substr(2)
    encodedAbi = encodedAbi.substr(24, 104) + encodedAbi.substr(2 * 24 + 104);

    const sign = hre.ethers.utils.solidityKeccak256(['bytes'], ['0x' + encodedAbi]);
    return hre.web3.eth.sign(sign, process.env.MAIN_DEPLOYER);
}

function printTestCasesResults(testCases) {
    testCases.forEach(testCase => {
        console.log("\x1b[36m" + testCase['function'] + " -> " + (testCase['condition']?"\x1b[32mpass":"\x1b[31mfailed") + "\x1b[0m");
    })
}

function addTestCase(testCases, condition, func, assertion=false) {
    if (assertion) {
        assert(condition, func + " doesn't work properly");
    }
    testCases.push({'condition': condition, 'function': func});

}

const ZERO_ADDRESS = "0x0000000000000000000000000000000000000000";

module.exports = {
    sleep,
    assert,
    getRandomAddress,
    printSuccess,
    oracleServerSign,
    printTestCasesResults,
    addTestCase,
    ZERO_ADDRESS
}
