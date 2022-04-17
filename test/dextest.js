const Dex = artifacts.require("Dex");
const Doge = artifacts.require("Doge");
const truffleAssert = require('truffle-assertions');

contract.skip( "Dex" , accounts => {
    it("limit order test: user must have more ETH than buy order value", async() =>{
        let dex = await Dex.deployed()
        let doge = await Doge.deployed()
        // transferir ETH para account[0]
        dex.depositEth({value: 10000, from: accounts[0]})
        await truffleAssert.reverts(
             dex.limitOrder( web3.utils.fromUtf8("DOGE"), true, 2000, 10, {from: accounts[0]})
        )
        await truffleAssert.passes(
            dex.limitOrder( web3.utils.fromUtf8("DOGE"), true, 2000, 5, {from: accounts[0]})
        )
        await truffleAssert.passes(
            dex.limitOrder(web3.utils.fromUtf8("DOGE"), true, 1000, 10, {from: accounts[0]})
        )
    })
    it("limit order test: user should have balance >= sell order", async() => {
        let dex = await Dex.deployed()
        let doge = await Doge.deployed()
        //account[0] tem saldo de 100000 (doge.constructor)
        await dex.addToken(web3.utils.fromUtf8("DOGE"), doge.address, {from: accounts[0]})
        await doge.approve(dex.address, 100000, {from:accounts[0]})
        await dex.deposit(100000, web3.utils.fromUtf8("DOGE"), {from: accounts[0]} )
        await truffleAssert.reverts(
            dex.limitOrder( web3.utils.fromUtf8("DOGE"), false, 105000, 7, {from: accounts[0]})
        )
        await truffleAssert.passes(
            dex.limitOrder( web3.utils.fromUtf8("DOGE"), false, 90000, 7, {from: accounts[0]})
        )
    })
    it("limit order test: the buy orderbook should be order by price high to low", async() => {
        let dex = await Dex.deployed()
        let doge = await Doge.deployed()
        // depositar 1 ETH na conta de account[1]/[2]
        dex.depositEth({value: 10000, from: accounts[1]})
        dex.depositEth({value: 10000, from: accounts[2]})
        await dex.limitOrder(web3.utils.fromUtf8("DOGE"), true, 5000, 1, {from: accounts[1]})
        await dex.limitOrder(web3.utils.fromUtf8("DOGE"), true, 2500, 2, {from: accounts[2]})
        
        let orderbook = await dex.getOrderbook(web3.utils.fromUtf8("DOGE"), true)
        console.log(orderbook)
        assert(orderbook.length > 0, "orderbook empty")
        for(let i=0; i < orderbook.length - 1; i++){
            assert(orderbook[i].price >= orderbook[i+1].price, "not right order in buy book")
        } //[3, 2, 1]
        // # 0, 1, 2 
    })
    it("limit order test: the sell order book should be order by  from low to high", async() => {
        let dex = await Dex.deployed()
        let doge = await Doge.deployed()
        await dex.withdraw(2000, web3.utils.fromUtf8("DOGE"), {from: accounts[0]})
        doge.transfer(accounts[1], 1000, {from: accounts[0]})
        doge.transfer(accounts[2], 1000, {from: accounts[0]})
        await doge.approve(dex.address, 1000, {from: accounts[1]})
        await doge.approve(dex.address, 1000, {from: accounts[2]})
        await dex.deposit(1000, web3.utils.fromUtf8("DOGE"), {from: accounts[1]})
        await dex.deposit(1000, web3.utils.fromUtf8("DOGE"), {from: accounts[2]})
        await dex.limitOrder( web3.utils.fromUtf8("DOGE"), false, 250, 4, {from: accounts[1]})
        await dex.limitOrder( web3.utils.fromUtf8("DOGE"), false, 500, 2, {from: accounts[2]})
        
        let orderbook = await dex.getOrderbook(web3.utils.fromUtf8("DOGE"), false)
        //console.log(orderbook)
        assert(orderbook.length > 0, "orderbook empty")
        for(let i=0 ; i < orderbook.length - 1 ; i++){
            assert(orderbook[i].price <= orderbook[i+1].price, "not right order in sell book")
        }
    })
})

contract( "Dex", accounts => {
   it("mkt order test: buyer should have enough wei to buy one unit of token", async() => {
       let dex = await Dex.deployed()
       let doge = await Doge.deployed()
       dex.depositEth( {value: 10 , from: accounts[0] } )
       dex.addToken( web3.utils.fromUtf8("DOGE"), doge.address )
       //account[0] doge balance = 100000
       doge.transfer(accounts[1], 30000, {from: accounts[0]})
       //account[0] doge balance = 70000
       doge.approve( dex.address, 30000, {from: accounts[1]})
       dex.deposit(30000, web3.utils.fromUtf8("DOGE"), {from: accounts[1]} )
       await dex.limitOrder( web3.utils.fromUtf8("DOGE"), false, 5000, 12, {from: accounts[1]}) 
       
       let test = await dex.marketOrder.call( web3.utils.fromUtf8("DOGE"), true, 1, {from: accounts[0]})
    //    console.log(test)
       assert( test.eq( web3.utils.toBN(0) ) , "test: marketOrder return unexpected")
       
   }) 
   it("mkt order BUY test: if the buyer has enough funds to cover the 1st price and 1st order can cover buy amount tx should complete",
    async() => {
        let dex = await Dex.deployed()
        let doge = await Doge.deployed()
        let book = await dex.getOrderbook(web3.utils.fromUtf8("DOGE"), false)
        dex.depositEth( {value: 100000 , from: accounts[0] } )
        let x = await dex.balances(accounts[0], web3.utils.fromUtf8("ETH") ) 
        console.log(x)
        console.log(book)
        
        let test = await dex.marketOrder.call( web3.utils.fromUtf8("DOGE"), true, 1000, {from: accounts[0]} )
        // console.log(test)//
        assert( test.eq( web3.utils.toBN(2) ), "FUNCTION RETURN UNEXPECTED")
        
    })
    it("mkt order BUY test: if the sell limit order is filled should be excluded from orderbook ", async() => {
        let dex = await Dex.deployed()
        let doge = await Doge.deployed()
        await dex.marketOrder(web3.utils.fromUtf8("DOGE"), true, 5000, {from: accounts[0]})
        let orderbook = await dex.getOrderbook( web3.utils.fromUtf8("DOGE"), false )
        console.log( orderbook )
        
        assert( orderbook.length == 0, "mkt order test: orderbook not empty")
    })
    // it("mkt order BUY test: if 1st limit order cannot cover BUY amount next order should be used (buyer has enough funds)",
    // async() => {
    //     let dex = await Dex.deployed()
    //     let doge = await Doge.deployed()
        
    //     await dex.limitOrder( web3.utils.fromUtf8("DOGE"), false, 500, 3, {from: accounts[1]})
    //     doge.transfer(accounts[2], 30000, {from: accounts[2]})
    //     await dex.limitOrder( web3.utils.fromUtf8("DOGE"), false, 1000, 4, {from: accounts[2]})
    //     let test = await dex.marketOrder( web3.utils.fromUtf8("DOGE"), true, 1000, {from:accounts[0]})
    //     assert( test == "tx complete", "test: tx not complete")
    //     let book = await dex.getOrderbook( web3.utils.fromUtf8("DOGE"), false)
    //     console.log(book)
    //     assert( book.length == 1, "sell orderbook not properly updated" )
    //     assert( book[0].amount == 500, "limit order amount not properly updated")
    // })
    // it("mkt order BUY test: if buyer does not have sufficient funds to complete the tx, it shoul be partially complete",
    // async() => {
    //     let dex = await Dex.deployed()
    //     let doge = await Doge.deployed()
    //     await dex.limitOrder( web3.utils.fromUtf8("DOGE"), false, 1000, 30)
    // })

 
})