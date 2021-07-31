const MultiWallet = artifacts.require("MultiWallet");

const truffleAssert = require('truffle-assertions');


contract("Wallet Tests", accounts => {
  let wallet;
  let ethticker = web3.utils.keccak256("ETH");

  before(async () => {
    wallet = await MultiWallet.deployed();
    let initBalanceAcc0;
    let initBalanceAcc1;
    let balanceAcc0;
    let balanceAcc1;

  })

  it("Owner should be able to add new admins", async () => {
console.log("\n BEGINNING TEST: Owner should be able to add new admins")
console.log("addAdmin('Billy Jean', accounts[1])")
    await truffleAssert.passes(
      wallet.addAdmin("Billy Jean", accounts[1])
    )
console.log("Passed")
console.log("addAdmin('Jilly Bean', accounts[2])")
    await truffleAssert.passes(
      wallet.addAdmin("Jilly Bean", accounts[2])
    )
console.log("Passed")
console.log("")
  })

  it("Admins cannot add other admins", async () => {
console.log("\n BEGINNING TEST: Admins cannot add other admins")
console.log("addAdmin('Dilly Bean', accounts[3], {from: accounts[2]})")
    await truffleAssert.reverts(
      wallet.addAdmin("Dilly Bean", accounts[3], {from: accounts[2]})
    )
console.log("Reverted")
console.log("")
  })

  it("Deposits should work", async () => {
console.log("\n BEGINNING TEST: Deposits should work")
console.log("depositETH({value: 1000})")
    await truffleAssert.passes(
      wallet.depositETH({value: 1000})
    )
console.log("walletBalance: " + await wallet.getBalance())
console.log("")
  })

  it("submitTransaction function should work", async () => {
console.log("\n BEGINNING TEST: submitTransaction function should work")
console.log("Transaction requests: " + await wallet.getRequestHistoryLength())
console.log("submitTransaction(accounts[1], 100, {from: accounts[0]})")
    await truffleAssert.passes(
    wallet.submitTransaction(accounts[1], 100, {from: accounts[0]})
    )
console.log("Transaction requests: " + await wallet.getRequestHistoryLength())

console.log("")
  })

  it("getTransfer function should work", async () => {
    console.log("\n BEGINNING TEST: getTransaction function should work")
    console.log("Logging getTransfer(0):")
    let txn0 = await wallet.getTransfer(0)
    console.log("getTransfer[0]:")
      console.log("   txID: " + txn0.txID)
      console.log("   toAddress: " + txn0.toAddress)
      console.log("   fromAddress: " + txn0.fromAddress)
      console.log("   amount: " + txn0.amount)
      console.log("   approvalStatus: " + txn0.approvalStatus + "\n")
    await truffleAssert.passes(
      wallet.getTransfer(0))
    console.log("Passes \n")
  })

  it("Confirm withdraw function should work", async () => {
    console.log("\n BEGINNING TEST: Confirm withdraw function should work")
    let transfer0 = await wallet.getTransfer(0)
    await truffleAssert.passes(transfer0.approvalStatus == "Submitted")
    console.log("confirmTransfer(0, {from: accounts[0]})")
    await truffleAssert.passes(
      wallet.confirmTransfer(0, {from: accounts[0]}))
    transfer0 = await wallet.getTransfer(0)
    console.log("txID0 approvalStatus: " + transfer0.approvalStatus)
    await truffleAssert.passes(transfer0.approvalStatus == "Pending")
    console.log("Passes \n")
  })

  it("getPending function should work", async () => {
    console.log("\n BEGINNING TEST: getPending function should work")
    await truffleAssert.passes(wallet.getPending())
    let pending = await wallet.getPending()
    console.log(pending.toNumber() + "\n")
  })

  it("Withdrawal should work", async () => {
  console.log("\n BEGINNING TEST: Withdrawal should work")
  console.log("walletBalance: " + await wallet.getBalance())
  console.log("getPending() = " + await wallet.getPending())
    let balance0 = await wallet.getBalance()
    let account1Bal0 = web3.eth.getBalance(accounts[1])
  console.log("Accounts[1] initial balance: " + await account1Bal0)
  console.log("Confirming transfer")
  console.log("getPending() = " + await wallet.getPending())
    await wallet.confirmTransfer(0, {from: accounts[1]})
  console.log("walletBalance: " + await wallet.getBalance())
    let balance1 = await wallet.getBalance()
    let account1Bal1 = web3.eth.getBalance(accounts[1])
  console.log("Accounts[1] final balance: " + await account1Bal1)
    await truffleAssert.passes(balance0 > balance1)
    await truffleAssert.passes(account1Bal0 < account1Bal1)
  console.log("")
  })

  it("submitTransaction should fail if walletBalance is low", async () => {
    console.log("\n BEGINNING TEST: submitTransaction should fail if walletBalance is low")
    console.log("submitTransaction(accounts[1], 10000)")
    await truffleAssert.reverts(wallet.submitTransaction(accounts[1], 10000))
    console.log("Reverts \n")
  })

  it("cancelTransaction function should work--only sender and owner may cancel", async () => {
    console.log("\n BEGINNING TEST: cancelTransaction function should work--only sender and owner may cancel");

    console.log("submitTransaction(accounts[2], 50), {from: accounts[1]}")
    await wallet.submitTransaction(accounts[2], 50, {from: accounts[1]})
    let txn1 = await wallet.requestHistory(1)

    console.log("submitTransaction(accounts[0], 25), {from:accounts[2]}")
    await wallet.submitTransaction(accounts[0], 25, {from:accounts[2]})
    let txn2 = await wallet.requestHistory(2)

    console.log("submitTransaction(accounts[0], 10), {from:accounts[2]}")
    await wallet.submitTransaction(accounts[0], 10, {from: accounts[2]})
    let txn3 = await wallet.requestHistory(3)

    console.log("requestHistoryLength = " + await wallet.getRequestHistoryLength())

    console.log("requestHistory[1]:")
      console.log("   txID: " + txn1.txID)
      console.log("   toAddress: " + txn1.toAddress)
      console.log("   fromAddress: " + txn1.fromAddress)
      console.log("   amount: " + txn1.amount)
      console.log("   approvalStatus: " + txn1.approvalStatus + "\n")
    console.log("cancelTransaction(1, {from: accounts[0]})")
    await truffleAssert.passes(
      wallet.cancelTransaction(1, {from: accounts[0]})
    )
    console.log("requestHistoryLength = " + await wallet.getRequestHistoryLength())
    console.log("Passes \n")

    console.log("requestHistory[2]:")
    console.log("   txID: " + txn2.txID)
    console.log("   toAddress: " + txn2.toAddress)
    console.log("   fromAddress: " + txn2.fromAddress)
    console.log("   amount: " + txn2.amount)
    console.log("   approvalStatus: " + txn2.approvalStatus + "\n")
    console.log("cancelTransaction(2, {from: accounts[2]})")
    await truffleAssert.passes(
      wallet.cancelTransaction(2, {from: accounts[2]})
    )
    console.log("requestHistoryLength = " + await wallet.getRequestHistoryLength())
    console.log("Passes \n")

    console.log("requestHistory[3]:")
    console.log("   txID: " + txn3.txID)
    console.log("   toAddress: " + txn3.toAddress)
    console.log("   fromAddress: " + txn3.fromAddress)
    console.log("   amount: " + txn3.amount)
    console.log("   approvalStatus: " + txn3.approvalStatus + "\n")
    console.log("cancelTransaction(3, {from: accounts[1]})")
    await truffleAssert.reverts(
      wallet.cancelTransaction(3, {from: accounts[1]})
    )
    await truffleAssert.passes(
      wallet.cancelTransaction(3, {from: accounts[0]})
    )
    console.log("requestHistoryLength = " + await wallet.getRequestHistoryLength())
    console.log("Reverts \n")

  })

  it("confirmTransfer should fail if walletBalance is low, failed txn should reset", async () => {
    console.log("\n BEGINNING TEST: confirmTransfer should fail if walletBalance is low, and request should auto-cancel")
console.log("getPending() = " + await wallet.getPending())
console.log("Wallet balance: " + await wallet.getBalance())
console.log("submitTransaction(accounts[1], 700)")
    await wallet.submitTransaction(accounts[1], 700)
console.log("submitTransaction(accounts[1], 500)")
    await wallet.submitTransaction(accounts[1], 500)

console.log(await wallet.getRequestHistory())

console.log("getRequestHistoryLength() = " + await wallet.getRequestHistoryLength())
console.log("getPending() = " + await wallet.getPending())
    let requestHistory0 = wallet.getRequestHistoryLength()
    let txnID1 = await wallet.requestHistory(1);
    let txnID2 = await wallet.requestHistory(2);

console.log("confirmTransfer(ID4, {from: accounts[0]}")
    await wallet.confirmTransfer(txnID1.txID, {from: accounts[0]})
    console.log(await wallet.getRequestHistory())

console.log("confirmTransfer(ID4, {from: accounts[1]}")
    await wallet.confirmTransfer(txnID1.txID, {from: accounts[1]})
    console.log(await wallet.getRequestHistory())
    console.log("getPending() = " + await wallet.getPending())
    console.log("Wallet balance: " + await wallet.getBalance())

console.log("confirmTransfer(ID5, {from: accounts[0]}")
    await wallet.confirmTransfer(txnID2.txID, {from: accounts[0]})
console.log("confirmTransfer(ID5, {from: accounts[1]}")
    await truffleAssert.passes(wallet.confirmTransfer(txnID2.txID, {from: accounts[1]}))
    await truffleAssert.passes(txnID1.approvalStatus == 2)
    await truffleAssert.passes(txnID2.approvalStatus == 0)
    await truffleAssert.passes(wallet.getRequestHistoryLength() < requestHistory0)
    await truffleAssert.passes(wallet.getPending() == 0)
    console.log("getRequestHistoryLength = " + await wallet.getRequestHistoryLength())
console.log("getPending() = " + await wallet.getPending())
console.log("getRequestHistory()")
console.log(await wallet.getRequestHistory())
  })

})
