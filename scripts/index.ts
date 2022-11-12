import { deployMain } from "./deploy";
import hre from 'hardhat';

async function main() {
  await deployMain(hre.network.name);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
