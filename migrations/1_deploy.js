var Vault = artifacts.require("Vault");
var System = artifacts.require("System")
var Exchange = artifacts.require("Exchange")
var Errors = artifacts.require("Errors")


// const ethers = require("ethers");
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

    // await deployer.deploy(Errors)
    // console.log("Errors deployed to:", Errors.address);
    // deployer.link(Errors, Vault)
    // deployer.link(Errors, Exchange)

    await deployer.deploy(Vault, System.address)
    console.log("Vault deployed to:", Vault.address);
    await deployer.deploy(Exchange, System.address)
    console.log("Exchange deployed to:", Exchange.address);
    await System.deployed().then(async function(instance) {
        await instance.setVault(Vault.address)
        await instance.setExchange(Exchange.address)
    })
};
