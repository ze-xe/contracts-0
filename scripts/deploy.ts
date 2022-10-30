import { ethers } from "hardhat";

async function main() {
  const Vault = await ethers.getContractFactory("Vault");
  const vault = await Vault.deploy();
  await vault.deployed();

  console.log("Vault deployed to:", vault.address);

  const Exchanger = await ethers.getContractFactory("Exchanger");
  const exchanger = await Exchanger.deploy(vault.address);
  await exchanger.deployed();

  console.log("Exchanger deployed to:", exchanger.address);


  await vault.updateExchangeAddress(exchanger.address);
  console.log("Exchanger address updated in Vault");

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
