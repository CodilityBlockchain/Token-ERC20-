// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.
const hre = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with the account:", deployer.address);

  const airdrop = await ethers.deployContract("Airdrop");
  console.log("Airdrop Contract Address",await airdrop.getAddress());

  const airdrop1 = await hre.ethers.deployContract("Airdrop1");
  console.log("Airdrop1 Contract Address",await airdrop1.getAddress());

  const launchpad = await hre.ethers.deployContract("Launchpad");
  console.log("Launchpad Contract Address",await launchpad.getAddress());

  const tokenFactory = await hre.ethers.deployContract("TokenFactory");
  console.log("TokenFactory Contract Address",await tokenFactory.getAddress());

  const presale = await hre.ethers.deployContract("Presale");
  console.log("Presale Contract Address",await presale.getAddress());

  const presale1 = await hre.ethers.deployContract("Presale1");
  console.log("Presale1 Contract Address",await presale1.getAddress());
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
