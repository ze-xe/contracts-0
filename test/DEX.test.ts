import { expect } from 'chai';
import hre from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

const ethers = hre.ethers;

describe('DEX', function () {
	let maker: SignerWithAddress, taker: SignerWithAddress;
	let storedSignatures: string[] = [];
	let limitOrder: Contract, eth: Contract, btc: Contract;
	let usdpool: any, btcpool: Contract;

	before(async () => {
		maker = (await ethers.getSigners())[0];
		taker = (await ethers.getSigners())[1];

		// deply limit order
		const limitOrderFactory = await ethers.getContractFactory('LimitOrderDEX');
		limitOrder = await limitOrderFactory.deploy();

		// deploy eth and btc
		eth = await ethers.getContractFactory('TestERC20').then((factory) => factory.deploy('ETH', 'ETH'));
		btc = await ethers.getContractFactory('TestERC20').then((factory) => factory.deploy('BTC', 'BTC'));
	});

	it('create pair', async () => {
		// create pair
		await limitOrder.createPair(eth.address, btc.address);
		const pair = await limitOrder.getPair(eth.address, btc.address);
		console.log(pair);
	});

	it('mint 10 ETH for maker, mint 1 BTC for taker', async () => {
		await eth.mint(maker.address, ethers.utils.parseEther('10'));
		await btc.mint(taker.address, ethers.utils.parseEther('1'));

		// approve for limitOrder
		await eth.connect(maker).approve(limitOrder.address, ethers.constants.MaxUint256);
		await btc.connect(taker).approve(limitOrder.address, ethers.constants.MaxUint256);
	});

	it('account0 creates limit order to sell', async function () {
		const domain = {
			name: 'LIMOLimitOrderDEX',
			version: '0.0.1',
			chainId: hre.network.config.chainId,
			verifyingContract: limitOrder.address,
		};

		// The named list of all type definitions
		const types = {
			Order: [
				{ name: 'maker', type: 'address' },
				{ name: 'token0', type: 'address' },
				{ name: 'token1', type: 'address' },
				{ name: 'orderType', type: 'uint256' },
				{ name: 'exchangeRate', type: 'uint256' },
				{ name: 'srcAmount', type: 'uint256' },
			],
		};

		// The data to sign
		const value = {
			maker: maker.address,
			token0: eth.address,
			token1: btc.address,
			orderType: '0',
			exchangeRate: ethers.utils.parseEther('20'),
			srcAmount: ethers.utils.parseEther('10'),
		};

		// sign typed data
		storedSignatures.push(await maker._signTypedData(domain, types, value));
	});

	it('send tx', async function () {
		await limitOrder.connect(taker).executeOrder(
					maker.address, 		// maker
                    eth.address,		// src
                    btc.address,		// dst
					0,					// orderType
					ethers.utils.parseEther('20'),  // exchangeRate
					ethers.utils.parseEther('10'),	// srcAmount
					ethers.utils.parseEther('5'),	// fillAmount
					storedSignatures[0]
				)

		await limitOrder.connect(taker).executeOrder(
					maker.address, 		// maker
                    eth.address,		// src
                    btc.address,		// dst
					0,					// orderType
					ethers.utils.parseEther('20'),  // exchangeRate
					ethers.utils.parseEther('10'),	// srcAmount
					ethers.utils.parseEther('5'),	// fillAmount
					storedSignatures[0]
				)

		// revert because fillAmount > srcAmount
		await expect(limitOrder.connect(taker).executeOrder(
				maker.address, 		// maker
				eth.address,		// src
				btc.address,		// dst
				0,					// orderType
				ethers.utils.parseEther('20'),  // exchangeRate
				ethers.utils.parseEther('10'),	// srcAmount
				ethers.utils.parseEther('5'),	// fillAmount
				storedSignatures[0]
			)).to.be.revertedWith('Order fill amount exceeds order amount');
		
		// check balances
		expect(await eth.balanceOf(taker.address)).to.equal(ethers.utils.parseEther('10'));
		expect(await btc.balanceOf(maker.address)).to.equal(ethers.utils.parseEther('0.5'));
	});
});
