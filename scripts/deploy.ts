import { Contract } from 'ethers';
import { ethers } from 'hardhat';

interface Deployments {
	system: Contract;
	vault: Contract;
	exchange: Contract;
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
	return { system, vault, exchange };
}
