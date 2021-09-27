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

async function getContractAt(contract, address) {
  const factory = await hre.ethers.getContractFactory(contract);
  const token = await factory.attach(address);

  console.log(`${contract} attached to:`, token.address);
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
  const map = await deployContract("MapNFT");
  await deployContract("MapNFTitems");
  const tower = await deployContract("TowerNFT");
  await deployContract("TowerNFTitems");

  //Set GameFactory
  await creature.setGameFactory(factory.address);
  await map.setGameFactory(factory.address);
  await tower.setGameFactory(factory.address);

  //Mint
  for (let i = 0; i < 20; i++)
    await creature.mint();
  for (let i = 0; i < 40; i++)
    await tower.mint();

  //make Sale
  for (let i = 0; i < 15; i++) {
    await factory.sellItem(creature.address, i + 1, hre.ethers.utils.parseEther((0.001 * (i + 1)).toString()));
  }
  for (let i = 0; i < 25; i++) {
    await factory.sellItem(tower.address, i + 1, hre.ethers.utils.parseEther((0.001 * (i + 1)).toString()));
  }


  // const creature = await getContractAt("CreatureNFT", "0x33228e503C174D7ce02b94D79bc6B75F9484cA2d");
  // const factory = await getContractAt("GameFactory", "0x6Fe5b87F1DE58Da1eCDC63F6DdB6Faead9e941B0");
  // const tower = await getContractAt("TowerNFT", "0x0A791867cEAA9d47e3424b8816dcDF4e3cA3A364");
  // //make approve
  // for (let i = 15; i < 40; i++) {
  //   await creature.approve(factory.address, i + 1);
  // }
  // for (let i = 35; i < 40; i++) {
  //   await tower.approve(factory.address, i + 1);
  // }
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch(error => {
    console.error(error);
    process.exit(1);
  });
