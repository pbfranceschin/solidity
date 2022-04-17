const Doge = artifacts.require("Doge");

module.exports = async function (deployer, network, accounts) {
  console.log("migrating DOGE to network");
  await deployer.deploy(Doge);
};
