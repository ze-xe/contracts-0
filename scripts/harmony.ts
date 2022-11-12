import { Contract } from 'ethers';
import { ethers } from 'hardhat';

interface Deployments {
	system: Contract;
	vault: Contract;
	exchange: Contract;
}

export default async function deploy(): Promise<Deployments> {
	/* -------------------------------------------------------------------------- */
	/*                                   System                                   */
	/* -------------------------------------------------------------------------- */
	const System = await ethers.getContractFactory('System');
	const system = await System.deploy();
	await system.deployed();

	/* -------------------------------------------------------------------------- */
	/*                                    Vault                                   */
	/* -------------------------------------------------------------------------- */
	const Vault = await ethers.getContractFactory('Vault');
	const vault = await Vault.deploy(system.address);
	await vault.deployed();
	console.log('Vault deployed to:', vault.address);

	await system.setVault(vault.address);

	/* -------------------------------------------------------------------------- */
	/*                                  Exchange                                  */
	/* -------------------------------------------------------------------------- */
	const Exchange = await ethers.getContractFactory('Exchange');
	const exchange = await Exchange.deploy(system.address);
	await exchange.deployed();

	console.log('Exchanger deployed to:', exchange.address);

	await system.setExchange(exchange.address);

	/* -------------------------------------------------------------------------- */
	/*                                   Tokens                                   */
	/* -------------------------------------------------------------------------- */
	const BTC = await ethers.getContractFactory('TestERC20');
	const btc = await BTC.deploy('Bitcoin', '1BTC');
	await btc.deployed();
    console.log("1BTC deployed to:", btc.address);

    const ETH = await ethers.getContractFactory('TestERC20');
	const eth = await ETH.deploy('Ethereum', '1ETH');
	await eth.deployed();
    console.log("1ETH deployed to:", eth.address);

    const ONE = await ethers.getContractFactory('TestERC20');
	const one = await ONE.deploy('Harmony One', 'ONE');
	await one.deployed();
    console.log("Harmony ONE deployed to:", one.address);

    const JEWEL = await ethers.getContractFactory('TestERC20');
	const jewel = await JEWEL.deploy('Defi Kingdoms', 'JEWEL');
	await jewel.deployed();
    console.log("JEWEL deployed to:", jewel.address);

	const USDT = await ethers.getContractFactory('TestERC20');
	const usdt = await USDT.deploy('USD Tether', '1USDT');
	await usdt.deployed();
    console.log("USDT deployed to:", usdt.address);

    const USDC = await ethers.getContractFactory('TestERC20');
	const usdc = await USDC.deploy('USD Coin', '1USDC');
	await usdc.deployed();
    console.log("USDC deployed to:", usdc.address);

	// create pair
	await exchange.createPair(btc.address, usdt.address, '2', ethers.utils.parseEther("0.000001"));
	await exchange.createPair(eth.address, usdt.address, '2', ethers.utils.parseEther("0.0001"));
	await exchange.createPair(jewel.address, usdt.address, '4', ethers.utils.parseEther("0.1"));
	await exchange.createPair(one.address, usdt.address, '5', ethers.utils.parseEther("1"));
    await exchange.createPair(usdc.address, usdt.address, '3', ethers.utils.parseEther("1"));

	return { system, vault, exchange };
}