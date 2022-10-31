import { expect } from 'chai';
import hre from 'hardhat';
import { Contract } from 'ethers';
import { SignerWithAddress } from '@nomiclabs/hardhat-ethers/signers';

const ethers = hre.ethers;
const web3 = require('web3');
const toWei = (x: { toString: () => any; }) => web3.utils.toWei(x.toString());
describe('Lim-O', function () {
	let  eth: Contract, btc: Contract, erc20: Contract, vault:Contract, exchange:Contract, system:Contract;
    let owner, user1:any, user2, user3, user4, user5, user6;

	before(async () => {
        [owner, user1, user2, user3, user4, user5, user6] =
        await ethers.getSigners();
		// deploy eth and btc, erc20
        erc20 = await ethers.getContractFactory('TestERC20').then((factory) => factory.deploy('ETH', 'ETH'));
		eth = await ethers.getContractFactory('TestERC20').then((factory) => factory.deploy('ETH', 'ETH'));
		btc = await ethers.getContractFactory('TestERC20').then((factory) => factory.deploy('BTC', 'BTC'));
    
        console.log(erc20.address);

       //deploy vault contract 
        const System = await ethers.getContractFactory('System');
        system =await System.connect(owner).deploy();
        console.log("system",system.address);

        //deploy vault contract 
        const Vault = await ethers.getContractFactory('Vault');
        vault =await Vault.connect(owner).deploy(system.address);
        console.log("vault",vault.address);

        //deploy exchange contract 
        const Exchange = await ethers.getContractFactory('Exchange');
        exchange =await Exchange.connect(owner).deploy(system.address);
        console.log("exchange", exchange.address);

        await system.connect(owner).setVault(vault.address);
        await system.connect(owner).setExchange(exchange.address);


	});

	it('create deposit1', async () => {
     await eth.mint(user1.address,100);
     await eth.connect(user1).approve(vault.address,100);
     await vault.connect(user1).deposit(eth.address,100);
     await expect( await vault.connect(user1).getBalance(eth.address)).to.be.equal(100);
     console.log(await vault.connect(user1).getBalance(eth.address));
	});

    it('create deposit2', async () => {
      await btc.mint(user1.address,10);
      await btc.connect(user1).approve(vault.address,10);
      await vault.connect(user1).deposit(btc.address, 10);
      await expect( await vault.connect(user1).getBalance(btc.address)).to.be.equal(10);
    });

	it('create withdraw', async () => {
     await vault.connect(user1).withdraw(eth.address, 10);
     await expect( await vault.connect(user1).getBalance(eth.address)).to.be.equal(90);
     await expect( await  eth.balanceOf(user1.address)).to.be.equal(10);
		
	});



    it('create order with wrong pair', async () => {
       await expect(exchange.connect(user1).createLimitOrder(btc.address, eth.address, 1, 0, 20)).to.be.revertedWithCustomError;
    });


    it('create new pair', async () => {
        await expect(exchange.connect(user1).createPair(btc.address, eth.address, 4, 1, 20)).to.be.revertedWithCustomError;

       await exchange.connect(owner).createPair(btc.address, eth.address, 4, 1, 20);

     });


    //  it('update exchange address ', async () => {
    //     await exchange.connect(user1).createLimitOrder(btc.address, eth.address, 1, 0, 20);
    //  });

     it('create order', async () => {
       let tx=  await exchange.connect(user1).createLimitOrder(btc.address, eth.address, 1, 0, 20); //sell order
       await expect(tx).to.emit(exchange, "OrderCreated");
       console.log(await vault.connect(user1).getBalance(btc.address));
     
     });

   


	

});
