const Dex = artifacts.require("Dex");
const Doge = artifacts.require("Doge");
const truffleAssert = require('truffle-assertions');

contract.skip("Dex" , accounts => {
    it("only owner can add tokens", async () => {
        let dex = await Dex.deployed()
        let doge = await Doge.deployed()
        await truffleAssert.passes(
            dex.addToken(web3.utils.fromUtf8("DOGE"), doge.address, {from: accounts[0]})
        )
        await truffleAssert.reverts(
            dex.addToken(web3.utils.fromUtf8("LINK"), doge.address, {from: accounts[1]})
        )
    })
    it("handling deposits", async() => {
        let dex = await Dex.deployed()
        let doge = await Doge.deployed()
        await doge.approve(dex.address, 5000)
        await truffleAssert.reverts(
            dex.deposit(5000, web3.utils.fromUtf8("LINK"), {from: accounts[0]})
        )
        await truffleAssert.reverts(
            dex.deposit(5000, web3.utils.fromUtf8("DOGE"), {from: accounts[1]})
        )
        await truffleAssert.passes(
            dex.deposit(5000, web3.utils.fromUtf8("DOGE"), {from: accounts[0]})
        )
    })
    it("withdraw function", async() => {
        let dex = await Dex.deployed()
        let doge = await Doge.deployed()
        //await dex.addToken(web3.utils.fromUtf8("DOGE"), doge.address, {from: accounts[0]})
        //await dex.deposit(5000, web3.utils.fromUtf8("DOGE"), {from: accounts[0]})
        await truffleAssert.reverts(
            dex.withdraw(8000, web3.utils.fromUtf8("DOGE"), {from: accounts[0]})
        )
        await truffleAssert.passes(
            dex.withdraw(3000, web3.utils.fromUtf8("DOGE"), {from: accounts[0]})
        )
    })
    
})