import { Contract } from 'ethers';
import { ethers } from 'hardhat';
import auroraDeploy from './aurora';

interface Deployments {
	system: Contract;
	vault: Contract;
	exchange: Contract;
	btc: Contract,
	usdt: Contract,
}

export async function deploy(): Promise<Deployments> {
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
	const BTC = await ethers.getContractFactory('BTC');
	const btc = await BTC.deploy();
	await btc.deployed();

	const USDT = await ethers.getContractFactory('USDT');
	const usdt = await USDT.deploy();
	await usdt.deployed();

	// create pair
	await exchange.createPair(btc.address, usdt.address, '6', ethers.utils.parseEther("0.000001"));

	return { system, vault, exchange, btc, usdt };
}

export const deployMain = async (network: string) => {
	if(network == 'aurora_testnet') auroraDeploy()
}