const MultiWallet = artifacts.require("MultiWallet");
const WalletUsers = artifacts.require("WalletUsers");

module.exports = async function (deployer, network, accounts) {
  await deployer.deploy(MultiWallet, "Phoenix", accounts[0]);

/*
  let wallet = await MultiWallet.deployed();
  let user = web3.utils.keccak256("USER_ROLE");

  await wallet.addUser("Billy Jean", accounts[1]);
  await wallet.addUser("Jilly Bean", accounts[2]);
  await wallet.hasRole(user, accounts[1]);
  await wallet.hasRole(user, accounts[2]);
*/
};
