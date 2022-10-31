var Vault = artifacts.require("Vault");
var System = artifacts.require("System")
var Exchange = artifacts.require("Exchange")
var Errors = artifacts.require("Errors")

var BTC = artifacts.require("BTC")
var ETH = artifacts.require("ETH")
var BTT = artifacts.require("BTT")
var USDD = artifacts.require("USDD")
var USDT = artifacts.require("USDT")
var TRX = artifacts.require("TRX")


const ethers = require("ethers");

// const fs = require("fs");
// const TronWeb = require('tronweb')
// const HttpProvider = TronWeb.providers.HttpProvider;
// const fullNode = new HttpProvider("https://api.trongrid.io");
// const solidityNode = new HttpProvider("https://api.trongrid.io");
// const eventServer = new HttpProvider("https://api.trongrid.io");
// const privateKey = "e58a6e240a4d5a32fe8ec34509cb0f7d631a8ea73771f09073c76213b64eb74a";
// const tronWeb = new TronWeb(fullNode,solidityNode,eventServer,privateKey);

module.exports = async function(deployer, network) {
    await deployer.deploy(System)
    console.log("System deployed to:", System.address);
    const system = await System.deployed();
    // await deployer.deploy(Errors)
    // console.log("Errors deployed to:", Errors.address);
    // deployer.link(Errors, Vault)
    // deployer.link(Errors, Exchange)

    await deployer.deploy(Vault, System.address)
    const vault = await Vault.deployed();
    console.log("Vault deployed to:", vault.address);
    await deployer.deploy(Exchange, System.address)
    const exchange = await Exchange.deployed();
    console.log("Exchange deployed to:", exchange.address);

    await system.setVault(vault.address)
    await system.setExchange(exchange.address)

    // deploy tokens
    await deployer.deploy(BTC)
    const btc = await BTC.deployed();
    console.log("BTC deployed to:", btc.address);
    await deployer.deploy(ETH)
    const eth = await ETH.deployed();
    console.log("ETH deployed to:", eth.address);
    await deployer.deploy(BTT)
    const btt = await BTT.deployed();
    console.log("BTT deployed to:", btt.address);
    await deployer.deploy(USDD)
    const usdd = await USDD.deployed();
    console.log("USDD deployed to:", usdd.address);
    await deployer.deploy(USDT)
    const usdt = await USDT.deployed();
    console.log("USDT deployed to:", usdt.address);
    await deployer.deploy(TRX)
    const trx = await TRX.deployed();
    console.log("TRX deployed to:", trx.address);

    // create pairs
    await exchange.createPair(btc.address, usdd.address, "6", ethers.utils.parseEther("0.000001").toString())
    console.log('BTC/USDD pair created')
    await exchange.createPair(eth.address, usdd.address, "4", ethers.utils.parseEther("0.0001").toString())
    console.log('ETH/USDD pair created')
    await exchange.createPair(btt.address, usdd.address, "12", ethers.utils.parseEther("1000000").toString())
    console.log('BTT/USDD pair created')
    await exchange.createPair(usdt.address, usdd.address, "4", ethers.utils.parseEther("1").toString())
    console.log('USDT/USDD pair created')
    await exchange.createPair(trx.address, usdd.address, "8", ethers.utils.parseEther("10").toString())
    console.log('TRX/USDD pair created')
};
