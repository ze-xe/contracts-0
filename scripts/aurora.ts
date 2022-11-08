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
	let System = await ethers.getContractFactory('System');
	const system = await System.deploy();
	await system.deployed();
    console.log("System deployed to:", system.address);

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
	const btc = await BTC.deploy('Bitcoin', 'BTC');
	await btc.deployed();
    console.log("BTC deployed to:", btc.address);

    const ETH = await ethers.getContractFactory('TestERC20');
	const eth = await ETH.deploy('Ethereum', 'ETH');
	await eth.deployed();
    console.log("ETH deployed to:", eth.address);

    const AURORA = await ethers.getContractFactory('TestERC20');
	const aurora = await AURORA.deploy('Aurora', 'AURORA');
	await aurora.deployed();
    console.log("AURORA deployed to:", aurora.address);

    const NEAR = await ethers.getContractFactory('TestERC20');
	const near = await NEAR.deploy('Near', 'NEAR');
	await near.deployed();
    console.log("NEAR deployed to:", near.address);

	const USDT = await ethers.getContractFactory('TestERC20');
	const usdt = await USDT.deploy('USD Tether', 'USDT');
	await usdt.deployed();
    console.log("USDT deployed to:", usdt.address);

    const USDC = await ethers.getContractFactory('TestERC20');
	const usdc = await USDC.deploy('USD Coin', 'USDC');
	await usdc.deployed();
    console.log("USDC deployed to:", usdc.address);

	// create pair
	await exchange.createPair(btc.address, usdt.address, '2', ethers.utils.parseEther("0.000001"));
	await exchange.createPair(eth.address, usdt.address, '2', ethers.utils.parseEther("0.0001"));
	await exchange.createPair(near.address, usdt.address, '3', ethers.utils.parseEther("0.1"));
	await exchange.createPair(aurora.address, usdt.address, '3', ethers.utils.parseEther("0.1"));
    await exchange.createPair(usdc.address, usdt.address, '2', ethers.utils.parseEther("1"));

	return { system, vault, exchange };
}