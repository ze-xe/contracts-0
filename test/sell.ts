import { expect } from 'chai';
import hre from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';
import { deploy } from '../scripts/deploy';

const ethers = hre.ethers;
const web3 = require('web3');
const toWei = (x: { toString: () => any }) => web3.utils.toWei(x.toString());

describe('zexe', function () {
	let usdt: Contract, btc: Contract, exchange: Contract, vault: Contract;
	let owner, user1: any, user2: any, user3, user4, user5, user6;
	let orderIds: string[] = [];
	before(async () => {
		[owner, user1, user2, user3, user4, user5, user6] =
			await ethers.getSigners();
		const deployments = await deploy();
		usdt = deployments.usdt;
		btc = deployments.btc;
		exchange = deployments.exchange;
		vault = deployments.vault;
	});

	it('mint 10 btc to user1, 1000000 usdt to user2', async () => {
		const btcAmount = ethers.utils.parseEther('10');
		await btc.mint(user1.address, btcAmount);
		await btc.connect(user1).approve(vault.address, btcAmount);
		await vault.connect(user1).deposit(btc.address, btcAmount);

		const usdtAmount = ethers.utils.parseEther('1000000');
		await usdt.mint(user2.address, usdtAmount);
		await usdt.connect(user2).approve(vault.address, usdtAmount);
		await vault.connect(user2).deposit(usdt.address, usdtAmount);
	});

	it('create limit order to buy 1 btc @ 19100', async () => {
		const btcAmount = ethers.utils.parseEther('1');
		const ex = await exchange.connect(user2).executeAndPlaceOrder(
			btc.address,
			usdt.address,
			btcAmount,
			19100 * 10 ** 6,
			1, // buy
			[]
		);

		const result = await ex.wait();
		orderIds.push(result.events[0].args.orderId);
	});

	it('create limit order to buy 2 btc @ 18000', async () => {
		let user2USDTBalance = await vault.userTokenBalance(user2.address, usdt.address);
		expect(user2USDTBalance).to.equal(ethers.utils.parseEther('980900'));

		const btcAmount = ethers.utils.parseEther('2');
		const ex = await exchange.connect(user2).executeAndPlaceOrder(
			btc.address,
			usdt.address,
			btcAmount,
			18000 * 10 ** 6,
			1, // buy
			[]
		);

		const result = await ex.wait();
		orderIds.push(result.events[0].args.orderId);

		user2USDTBalance = await vault.userTokenBalance(user2.address, usdt.address);
		expect(user2USDTBalance).to.equal(ethers.utils.parseEther('944900'));
	});

	it('sells user1s 3 btc order @ 19500', async () => {
		let user1USDTBalance = await vault.userTokenBalance(user1.address, usdt.address);
		expect(user1USDTBalance).to.equal(ethers.utils.parseEther('0'));

		const btcAmount = ethers.utils.parseEther('3');
		let tx = await exchange.connect(user1).executeAndPlaceOrder(
			btc.address,
			usdt.address,
			btcAmount,
			19500 * 10 ** 6,
			0, // sell
			[...orderIds, ethers.utils.namehash('invalidorder')]
		);
		tx = await tx.wait();
		// console.log(tx.events)

		let user1BtcBalance = await vault.userTokenBalance(user1.address, btc.address);
		expect(user1BtcBalance).to.equal(ethers.utils.parseEther('7'));
		let user2BtcBalance = await vault.userTokenBalance(user2.address, btc.address);
		expect(user2BtcBalance).to.equal(ethers.utils.parseEther('3'));
	});
});