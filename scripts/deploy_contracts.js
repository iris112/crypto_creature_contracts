// We require the Hardhat Runtime Environment explicitly here. This is optional 
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function deployContract(contract) {
  const factory = await hre.ethers.getContractFactory(contract);
  let token = await factory.deploy();

  await token.deployed();

  console.log(`${contract} deployed to:`, token.address);
  return token;
}

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile 
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const creature = await deployContract("CreatureNFT");
  await deployContract("CreatureNFTitems");
  await deployContract("DiamondToken");
  const factory = await deployContract("GameFactory");
  await deployContract("GameToken");
  await deployContract("MapNFT");
  await deployContract("MapNFTitems");
  await deployContract("TowerNFT");
  await deployContract("TowerNFTitems");

  //Set GameFactory
  await creature.setGameFactory(factory.address);

  //Mint
  for (let i = 0; i < 20; i++)
    await creature.mint();

  //make Sale
  for (let i = 0; i < 10; i++)
    await factory.sellItem(creature.address, i + 1, hre.ethers.utils.parseEther('0.001') * i);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
