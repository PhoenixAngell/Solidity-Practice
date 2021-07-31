const WalletUsers = artifacts.require("WalletUsers");

module.exports = function (deployer) {
  deployer.deploy(WalletUsers);
};
