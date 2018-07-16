var CustomCoin = artifacts.require("./CustomCoin.sol");

module.exports = function(deployer) {
  deployer.deploy(CustomCoin);
};
